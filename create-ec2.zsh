#!/usr/bin/env zsh

# Ensure AWS CLI is installed and configured

# Define parameters

# Region where the instance will be launched.
REGION=us-east-1

# The EC2 instance type determines the hardware of the host computer used for the instance.
# 't2.micro' is one of the instance types eligible for the AWS Free Tier and is suitable for low traffic applications.
INSTANCE_TYPE=t2.micro

# The Amazon Machine Image (AMI) provides the information required to launch an instance.
# This specific AMI ID represents an AWS Linux instance. Ensure this AMI is available in the specified region or update the ID.
AMI_ID=ami-08a52ddb321b32a8c

# The name for the key pair used for connecting to the EC2 instance.
# WARNING: Secure the key (.pem file). If lost or shared, anyone with the key can access your EC2 instance.
KEY_NAME=mybootcamp-key
KEY_FILE_PATH="$PWD/$KEY_NAME.pem"

# Security Group that will define which incoming/outgoing traffic is allowed to/from the instance.
SECURITY_GROUP_NAME=NodeJsSecurityGroup
INSTANCE_NAME=mybootcamp-instance

# Create the Key Pair only if it doesn't exist
echo "Checking for key pair..."
EXISTING_KEY_NAME=$(aws ec2 describe-key-pairs --region $REGION --query "KeyPairs[?KeyName=='$KEY_NAME'].KeyName | [0]" --output text)

if [[ "$EXISTING_KEY_NAME" != "$KEY_NAME" ]]; then
    echo "Creating key pair..."
    aws ec2 create-key-pair --key-name $KEY_NAME --region $REGION --query "KeyMaterial" --output text > $KEY_FILE_PATH
    echo "Key pair saved to $KEY_FILE_PATH"
    # IMPORTANT: This key (.pem file) will be used to connect to the EC2 instance via SSH. Store it securely and do not share.
else
    echo "Key pair $KEY_NAME already exists."
fi

# Check if the security group already exists
SG_ID=$(aws ec2 describe-security-groups --region $REGION --query "SecurityGroups[?GroupName=='$SECURITY_GROUP_NAME'].GroupId | [0]" --output text)

# If security group doesn't exist, create it and add rules
if [[ -z "$SG_ID" ]]; then
    SG_ID=$(aws ec2 create-security-group --region $REGION --group-name $SECURITY_GROUP_NAME --description "SG for EC2 instance to run Node.js" --query "GroupId" --output text)
    # Add SSH rule - Allows SSH access from any IP. WARNING: This is insecure for production environments.
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
    # Add rule for port 3000 - Allows incoming traffic on port 3000 from any IP. This is commonly used for web apps.
    aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0
fi

# Launch EC2 instance in the specified region and set its name using tags
INSTANCE_ID=$(aws ec2 run-instances --region $REGION --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query "Instances[0].InstanceId" --output text)

echo "EC2 Instance with ID $INSTANCE_ID named $INSTANCE_NAME is being created..."
