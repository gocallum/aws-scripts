#!/bin/bash

# Ensure AWS CLI is installed and configured

# Define parameters
REGION=us-east-1
INSTANCE_TYPE=t2.micro
AMI_ID=ami-08a52ddb321b32a8c
KEY_NAME=mybootcamp-key
KEY_FILE_PATH="./${KEY_NAME}.pem"
SECURITY_GROUP_NAME=NodeJsSecurityGroup

# Check if the key pair already exists
EXISTING_KEY_NAME=$(aws ec2 describe-key-pairs --region $REGION --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName | [0]" --output text)

if [ "$EXISTING_KEY_NAME" != "$KEY_NAME" ]; then
    echo "Creating key pair..."
    aws ec2 create-key-pair --key-name $KEY_NAME --region $REGION --query "KeyMaterial" --output text > $KEY_FILE_PATH
    echo "Key pair saved to $KEY_FILE_PATH"
else
    echo "Key pair $KEY_NAME already exists."
fi

# Check if the security group already exists
SG_ID=$(aws ec2 describe-security-groups --region $REGION --query "SecurityGroups[?GroupName=='$SECURITY_GROUP_NAME'].GroupId | [0]" --output text)

# If security group doesn't exist, create it and add rules
if [ -z "$SG_ID" ]; then
    SG_ID=$(aws ec2 create-security-group --region $REGION --group-name $SECURITY_GROUP_NAME --description "SG for EC2 instance to run Node.js" --query "GroupId" --output text)
    # Add rules
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0
fi

# Launch EC2 instance in the specified region and set its name using tags
INSTANCE_ID=$(aws ec2 run-instances --region $REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=mybootcamp-instance}]" --query "Instances[0].InstanceId" --output text)

echo "EC2 Instance with ID $INSTANCE_ID is being created..."
