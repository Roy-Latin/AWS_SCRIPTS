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

