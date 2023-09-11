@echo off
REM Ensure AWS CLI is installed and configured

REM Define parameters
set REGION=us-east-1
set INSTANCE_TYPE=t2.micro
set AMI_ID=ami-08a52ddb321b32a8c
set KEY_NAME=mybootcamp-key
set KEY_FILE_PATH=%CD%\%KEY_NAME%.pem
set SECURITY_GROUP_NAME=NodeJsSecurityGroup

REM Create the Key Pair only if it doesn't exist
echo Checking for key pair...
for /f "tokens=*" %%i in ('aws ec2 describe-key-pairs --region %REGION% --query "KeyPairs[?KeyName=='%KEY_NAME%'].KeyName | [0]" --output text') do set EXISTING_KEY_NAME=%%i

if not "%EXISTING_KEY_NAME%"=="%KEY_NAME%" (
    echo Creating key pair...
    aws ec2 create-key-pair --key-name %KEY_NAME% --region %REGION% --query "KeyMaterial" --output text > %KEY_FILE_PATH%
    echo Key pair saved to %KEY_FILE_PATH%
) else (
    echo Key pair %KEY_NAME% already exists.
)

REM Check if the security group already exists
for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --region %REGION% --query "SecurityGroups[?GroupName=='%SECURITY_GROUP_NAME%'].GroupId | [0]" --output text') do set SG_ID=%%i

REM If security group doesn't exist, create it and add rules
if not defined SG_ID (
    for /f "tokens=*" %%i in ('aws ec2 create-security-group --region %REGION% --group-name %SECURITY_GROUP_NAME% --description "SG for EC2 instance to run Node.js" --query "GroupId" --output text') do set SG_ID=%%i
    REM Add rules
    aws ec2 authorize-security-group-ingress --region %REGION% --group-id %SG_ID% --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --region %REGION% --group-id %SG_ID% --protocol tcp --port 3000 --cidr 0.0.0.0/0
)

REM Launch EC2 instance in the specified region and set its name using tags
for /f "tokens=*" %%i in ('aws ec2 run-instances --region %REGION% --image-id %AMI_ID% --count 1 --instance-type %INSTANCE_TYPE% --key-name %KEY_NAME% --security-group-ids %SG_ID% --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=mybootcamp-instance}]" --query "Instances[0].InstanceId" --output text') do set INSTANCE_ID=%%i

echo EC2 Instance with ID %INSTANCE_ID% is being created...

pause
