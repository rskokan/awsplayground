#!/bin/bash -e

AMIID=$(aws ec2 describe-images --filters "Name=description,Values=Amazon Linux * x86_64 HVM" --query "Images[0].ImageId"  --output text)
echo "AMIID=$AMIID"

VPCID=$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)
echo "VPCID=$VPCID"

SUBNETID=$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)
echo "SUBNETID=$SUBNETID"

SGID=$(aws ec2 create-security-group --group-name mysecuritygroup --description "My Security Group" --vpc-id $VPCID --output text)
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "SGID=$SGID"

INSTANCEID=$(aws ec2 run-instances --image-id $AMIID --key-name aws1-key-1 --instance-type t2.micro --security-group-ids $SGID --subnet-id $SUBNETID --query "Instances[0].InstanceId" --output text)

echo "Waiting for $INSTANCEID..."
aws ec2 wait instance-running --instance-ids $INSTANCEID

PUBLICNAME=$(aws ec2 describe-instances --instance-ids $INSTANCEID --query "Reservations[0].Instances[0].PublicDnsName" --output text)

echo "$INSTANCEID is accepting SSH connections at $PUBLICNAME"
echo "ssh -i aws1-key-1.pem ec2-user@$PUBLICNAME"

read -p "Press [Enter] to terminate $INSTANCEID..."

aws ec2 terminate-instances --instance-ids $INSTANCEID
echo "Terminating $INSTANCEID"

aws ec2 wait instance-terminated --instance-ids $INSTANCEID
aws ec2 delete-security-group --group-id $SGID

