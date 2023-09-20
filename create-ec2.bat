@echo off
REM Ensure AWS CLI is installed and configured

REM Define parameters

REM Region where the instance will be launched.
set REGION=us-east-1

REM The EC2 instance type determines the hardware of the host computer used for the instance.
REM 't2.micro' is one of the instance types eligible for the AWS Free Tier and is suitable for low traffic applications.
set INSTANCE_TYPE=t2.micro

REM The Amazon Machine Image (AMI) provides the information required to launch an instance.
REM This specific AMI ID represents an AWS Linux instance. Ensure this AMI is available in the specified region or update the ID.
set AMI_ID=ami-08a52ddb321b32a8c

REM The name for the key pair used for connecting to the EC2 instance.
REM WARNING: Secure the key (.pem file). If lost or shared, anyone with the key can access your EC2 instance.
set KEY_NAME=mybootcamp-key
set KEY_FILE_PATH=%CD%\%KEY_NAME%.pem

REM Security Group that will define which incoming/outgoing traffic is allowed to/from the instance.
set SECURITY_GROUP_NAME=NodeJsSecurityGroup
set INSTANCE_NAME=mybootcamp-instance

REM Create the Key Pair only if it doesn't exist
echo Checking for key pair...
for /f "tokens=*" %%i in ('aws ec2 describe-key-pairs --region %REGION% --query "KeyPairs[?KeyName=='%KEY_NAME%'].KeyName | [0]" --output text') do set EXISTING_KEY_NAME=%%i

if not "%EXISTING_KEY_NAME%"=="%KEY_NAME%" (
    echo Creating key pair...
    aws ec2 create-key-pair --key-name %KEY_NAME% --region %REGION% --query "KeyMaterial" --output text > %KEY_FILE_PATH%
    echo Key pair saved to %KEY_FILE_PATH%
    REM IMPORTANT: This key (.pem file) will be used to connect to the EC2 instance via SSH. Store it securely and do not share.
) else (
    echo Key pair %KEY_NAME% already exists.
)

REM Check if the security group already exists
for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --region %REGION% --query "SecurityGroups[?GroupName=='%SECURITY_GROUP_NAME%'].GroupId | [0]" --output text') do set SG_ID=%%i

REM If security group doesn't exist, create it and add rules
if not defined SG_ID (
    for /f "tokens=*" %%i in ('aws ec2 create-security-group --region %REGION% --group-name %SECURITY_GROUP_NAME% --description "SG for EC2 instance to run Node.js" --query "GroupId" --output text') do set SG_ID=%%i
    
    REM Add SSH rule - Allows SSH access from any IP. WARNING: This is insecure for production environments.
    aws ec2 authorize-security-group-ingress --region %REGION% --group-id %SG_ID% --protocol tcp --port 22 --cidr 0.0.0.0/0
    
    REM Add rule for port 3000 - Allows incoming traffic on port 3000 from any IP. This is commonly used for web apps.
    aws ec2 authorize-security-group-ingress --region %REGION% --group-id %SG_ID% --protocol tcp --port 3000 --cidr 0.0.0.0/0
)

REM Launch EC2 instance in the specified region and set its name using tags
for /f "tokens=*" %%i in ('aws ec2 run-instances --region %REGION% --image-id %AMI_ID% --count 1 --instance-type %INSTANCE_TYPE% --key-name %KEY_NAME% --security-group-ids %SG_ID% --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=%INSTANCE_NAME%}]" --query "Instances[0].InstanceId" --output text') do set INSTANCE_ID=%%i

echo EC2 Instance with ID %INSTANCE_ID% named %INSTANCE_NAME% is being created...

pause
