#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0a57c1e73eeeeb737"
ZONE_ID="Z07458192RR2CQRCYPMGD"
DOMAIN_NAME="harshithdaws-86s.fun"

for instance in "$@"
do
    echo "🚀 Launching $instance instance..."

    # Run EC2 instance
    Instance_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids $Instance_ID

    # Get IP address
    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids $Instance_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $Instance_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance ($Instance_ID): $IP"

    # Create/Update DNS record in Route53
    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch "{
        \"Changes\": [{
          \"Action\": \"UPSERT\",
          \"ResourceRecordSet\": {
            \"Name\": \"$RECORD_NAME\",
            \"Type\": \"A\",
            \"TTL\": 60,
            \"ResourceRecords\": [{\"Value\": \"$IP\"}]
          }
        }]
      }"

    echo "✅ DNS record created: $RECORD_NAME -> $IP"
done
