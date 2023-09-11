#!/bin/bash
# Create RDS PostgreSQL instance

INSTANCE_NAME="my-postgres-instance"
DB_USERNAME="postgres"
DB_PASSWORD="ilovebootcamp1234"
DB_NAME="awsbootcamp"

aws rds create-db-instance \
    --db-name $DB_NAME \
    --db-instance-identifier $INSTANCE_NAME \
    --allocated-storage 20 \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 15.3 \
    --master-username $DB_USERNAME \
    --master-user-password $DB_PASSWORD \
    --publicly-accessible \
    --port 5432 \
    --no-multi-az \
    --region us-east-1 \
    --storage-encrypted

# Give some time for the DB instance to be created before modifying the security group
echo "Waiting for the RDS instance to become available..."
aws rds wait db-instance-available --db-instance-identifier $INSTANCE_NAME --region us-east-1

# Fetch the default security group associated with the RDS instance
SECURITY_GROUP_ID=$(aws rds describe-db-instances --db-instance-identifier $INSTANCE_NAME --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' --output text --region us-east-1)

# Modify the security group to allow inbound traffic from anywhere on port 5432
aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 5432 \
    --cidr 0.0.0.0/0 \
    --region us-east-1

echo "The encrypted PostgreSQL instance has been created and is now accessible from anywhere on the internet."
