#!/bin/bash

if [ "$1" = "start" ]; then
    STOPPED_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text))
    echo "Starting instances..."
    aws ec2 start-instances --instance-ids "${STOPPED_INSTANCE_IDS[@]}"
fi

if [ "$1" = "stop" ]; then
    RUNNING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text))
    echo "Stopping instances..."
    aws ec2 stop-instances --instance-ids "${RUNNING_INSTANCE_IDS[@]}"
fi

if [ "$1" = "destroy" ]; then
  RUNNING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text))
  STOPPED_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text))
  echo "Terminating instances..."
  aws ec2 terminate-instances --instance-ids "${RUNNING_INSTANCE_IDS[@]}"
  aws ec2 start-instances --instance-ids "${STOPPED_INSTANCE_IDS[@]}"
fi


if [ "$1" = "create" ]; then
  echo "creating instance..."
  aws ec2 run-instances --image-id "ami-0715c1897453cabd1" --instance-type "t2.micro" --key-name "key" --security-group-ids "launch-wizard-1" --subnet-id "subnet-04a1b30c46b166e42" 
  git clone https://github.com/Roy-Latin/DevOps-Crypto.git /home/ec2-user/

fi
