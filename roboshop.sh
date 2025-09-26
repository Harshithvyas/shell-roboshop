#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0a57c1e73eeeeb737"

for instance in "$@"
do
    # Run EC2 instance
    Instance_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' \
        --query 'Instances[0].InstanceId' \
        --output text)

    # Get IP address
    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids $Instance_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $Instance_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    fi

    echo "$instance: $IP"
done
