#!/bin/bash

# VIRTUAL MACHINE PLACEMENT IN AWS

# Define Variables
PLACEMENT_GROUP_NAME="placement-group-01"
PLACEMENT_STRATEGY="cluster" # This can also be "spread" or "partition". 
REGION="me-central-1"
AMI_ID="ami-xxxxxxxxxxxx"
INSTANCE_TYPE="c5.large"
SUBNET_ID="subnet-xxxxxxx"
KEY_NAME="pg-key-pair"

# Create the Placement Group
aws ec2 create-placement-group --group-name "$PLACEMENT_GROUP_NAME" \
  --strategy "$PLACEMENT_STRATEGY" --region "$REGION" # For Partition Placement Group, include --partition-count

# Verify that the Placement Group was created successfully
aws ec2 describe-placement-groups --group-names "$PLACEMENT_GROUP_NAME" --region "$REGION" > /dev/null 2>&1 

if [ $? -eq 0 ]; then 
    echo "Placement Group '$PLACEMENT_GROUP_NAME' created with strategy '$PLACEMENT_STRATEGY'."
else 
    echo "Error: Failed to create Placement Group '$PLACEMENT_GROUP_NAME'."
    exit 1
fi 

# Launch EC2 Instance in the Placement Group
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --subnet-id "$SUBNET_ID" \
    --placement "GroupName=$PLACEMENT_GROUP_NAME" \
    --key-name "$KEY_NAME" \
    --query 'Instances[0].InstanceId' \
    --output text)

sleep 10 

# Verify that the EC2 Instance was launched successfully  
if [ -n "$INSTANCE_ID" ]; then 
    echo "EC2 Instance '$INSTANCE_ID' launched in Placement Group '$PLACEMENT_GROUP_NAME'."
else 
    echo "Error: Failed to launch EC2 instance in Placement Group '$PLACEMENT_GROUP_NAME'."
    exit 1
fi 