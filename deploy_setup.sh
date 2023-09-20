#!/bin/bash

# Variables
APP_NAME=$1
DEPLOYMENT_GROUP_NAME=$2
INSTANCE_TAG_VALUE=$3
S3_BUCKET_NAME="${APP_NAME}-artifacts"
INSTANCE_TAG_KEY="Name"
ZIP_FILE_PATH=$4  # Path to the application package zip files

# Check input
if [[ -z $APP_NAME ]] || [[ -z $DEPLOYMENT_GROUP_NAME ]] || [[ -z $INSTANCE_TAG_VALUE ]] || [[ -z $ZIP_FILE_PATH ]]; then
    echo "Usage: $0 <app_name> <deployment_group_name> <ec2_instance_tag_value> <path_to_zip_file>"
    exit 1
fi

# Create S3 bucket if it doesn't exist
if ! aws s3 ls "s3://$S3_BUCKET_NAME" &> /dev/null ; then
    aws s3api create-bucket --bucket $S3_BUCKET_NAME --region us-west-1
    echo "S3 bucket $S3_BUCKET_NAME created."
fi

# Upload the application package to the S3 bucket
ZIP_FILE_NAME=$(basename $ZIP_FILE_PATH)
aws s3 cp $ZIP_FILE_PATH s3://$S3_BUCKET_NAME/$ZIP_FILE_NAME

# Create CodeDeploy application
aws deploy create-application --application-name $APP_NAME

# Create IAM Role for CodeDeploy with the updated name
ROLE_NAME="CodeDeploy-EC2-Role"
POLICY_ARN="arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
S3_READONLY_POLICY_ARN="arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"

# Check if the role exists, if not then create it
if ! aws iam get-role --role-name $ROLE_NAME &> /dev/null ; then
    aws iam create-role --role-name $ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "codedeploy.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }'
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $S3_READONLY_POLICY_ARN
    echo "IAM Role $ROLE_NAME created and policies attached."
fi

# Wait a bit to ensure the IAM role is fully propagated
sleep 10

# Create Deployment Group with default EC2/On-Premises and CodeDeployDefault.AllAtOnce configuration
aws deploy create-deployment-group \
    --application-name $APP_NAME \
    --deployment-group-name $DEPLOYMENT_GROUP_NAME \
    --deployment-config-name CodeDeployDefault.AllAtOnce \
    --ec2-tag-filters Key=$INSTANCE_TAG_KEY,Value=$INSTANCE_TAG_VALUE,Type=KEY_AND_VALUE \
    --service-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME

# Create Deployment using the uploaded application package
aws deploy create-deployment \
    --application-name $APP_NAME \
    --deployment-group-name $DEPLOYMENT_GROUP_NAME \
    --s3-location bucket=$S3_BUCKET_NAME,bundleType=zip,key=$ZIP_FILE_NAME

echo "Application and Deployment Group created, and deployment initiated!"
