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
  new_instance=$(aws ec2 run-instances --image-id "ami-0715c1897453cabd1" --instance-type "t2.micro" --key-name "key" --security-group-ids "sg-0582c9864fa0768cc" --subnet-id "subnet-04a1b30c46b166e42"  --count "1" --output text --query 'Instances[0].InstanceId' --user-data '#!/bin/bash
sudo yum update -y
sudo yum install python3 python3-pip python3-devel -y
pip3 install flask -y
sudo yum install git -y
sudo pip install gunicorn -y
sudo git clone https://github.com/Roy-Latin/DevOps-Crypto.git /home/ec2-user/Git
sudo echo -e "[Unit]\nDescription=Flask Web Application\nAfter=network.target\n\n[Service]\nUser=ec2-user\nWorkingDirectory=/home/ec2-user/Git\nExecStart=gunicorn --bind 0.0.0.0:5000 app:app &\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/flaskapp.service
')

echo "Instance created with ID: $new_instance"
echo "cloned the git repo into /home/ec2-user/Git"
sleep 45
aws ec2 create-image --instance-id $new_instance --name "update" --description "AMI update for flask"
echo "created AMI"
sleep 250
aws ec2 terminate-instances --instance-ids $new_instance
echo "deleted the mechince with the ID of: $new_instance"
fi
