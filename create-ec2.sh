#!/bin/bash

# Variables
REGION="us-east-1"
INSTANCE_NAME="YourInstanceName" # Replace with your desired instance name
AMI_ID="ami-08a52ddb321b32a8c"
INSTANCE_TYPE="t2.micro"
KEY_NAME="mybootcamp-key"
SECURITY_GROUP_NAME="NodeJsSecurityGroup"
IAM_ROLE_NAME="EC2CodeDeployRole"

# IAM Role for CodeDeploy
aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}' || echo "IAM Role $IAM_ROLE_NAME already exists or encountered an error."

aws iam put-role-policy --role-name $IAM_ROLE_NAME --policy-name CodeDeploy-EC2 --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}' || echo "Policy might already be attached or encountered an error."

# Launch EC2 Instance
aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_NAME \
  --iam-instance-profile Name=$IAM_ROLE_NAME \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --user-data '#!/bin/bash
    echo "Starting installations..." >> /var/log/user_data.log
    echo "Updating yum..." >> /var/log/user_data.log
    yum update -y

    echo "Installing Git..." >> /var/log/user_data.log
    yum install -y git && echo "Git Installed." >> /var/log/user_data.log

    echo "Installing NodeJS..." >> /var/log/user_data.log
    yum install -y nodejs && echo "NodeJS Installed." >> /var/log/user_data.log

    echo "Installing TypeScript and ts-node globally..." >> /var/log/user_data.log
    npm install -g typescript ts-node && echo "TypeScript and ts-node Installed." >> /var/log/user_data.log

    echo "Setting up AWS CodeDeploy Agent..." >> /var/log/user_data.log
    yum install -y ruby
    yum install -y wget
    cd /home/ec2-user
    wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto && echo "CodeDeploy Agent Installed and Started." >> /var/log/user_data.log
    service codedeploy-agent start' \
  --output text

echo "EC2 instance is being created with necessary software and configurations."
