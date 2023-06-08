#!/bin/bash
echo "please select what AWS command you want:| start | stop | destroy | AMI |"
read input
#start all stopped instances
if [ "$input" = "start" ]; then
    #takes the ID'S of all stopped and stopping instances
    STOPPED_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text))
    STOPPING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopping" --query "Reservations[].Instances[].InstanceId" --output text))
    echo "Starting instances..."
    #starts all the instances with the gatherd ID'S
    aws ec2 start-instances --instance-ids "${STOPPED_INSTANCE_IDS[@]}"
    aws ec2 start-instances --instance-ids "${STOPPING_INSTANCE_IDS[@]}"
fi

#stop all running instances
if [ "$input" = "stop" ]; then
    #takes the ID'S of all running and pending instances
    RUNNING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text))
    PENDING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending" --query "Reservations[].Instances[].InstanceId" --output text))
    echo "Stopping instances..."
    #stops all the instances with the gatherd ID'S
    aws ec2 stop-instances --instance-ids "${RUNNING_INSTANCE_IDS[@]}"
    aws ec2 stop-instances --instance-ids "${PENDING_INSTANCE_IDS[@]}"
fi

#terminate all instances
if [ "$input" = "destroy" ]; then
  #takes the ID'S of all running instances
  RUNNING_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text))
  #takes the ID'S of all stopped instances
  STOPPED_INSTANCE_IDS=($(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query "Reservations[].Instances[].InstanceId" --output text))
  echo "Terminating instances..."
  #terminates all the instances with the gatherd ID'S 
  aws ec2 terminate-instances --instance-ids "${RUNNING_INSTANCE_IDS[@]}"
  aws ec2 start-instances --instance-ids "${STOPPED_INSTANCE_IDS[@]}"
fi

#create a new AMI 
if [ "$input" = "AMI" ]; then
  #creates a new instance with the information below and puts in the user data a script to install tools, clone git repo, create a service file and run the flask, all happening on instance startup
  echo "creating instance..."
  new_instance=$(aws ec2 run-instances --image-id "ami-0715c1897453cabd1" --instance-type "t2.micro" --key-name "key" --security-group-ids "sg-0582c9864fa0768cc" --subnet-id "subnet-04a1b30c46b166e42"  --count "1" --output text --query 'Instances[0].InstanceId' --user-data '#!/bin/bash
sudo yum update -y
sudo yum install python3 python3-pip python3-devel -y
pip3 install flask 
sudo yum install git -y
sudo pip install gunicorn
sudo git clone https://github.com/Roy-Latin/DevOps-Crypto.git /home/ec2-user/Git
while [ ! -d "/home/ec2-user/Git" ]; do
    sleep 5
done

sudo echo -e "[Unit]\nDescription=Flask Web Application\nAfter=network.target\n\n[Service]\nUser=ec2-user\nWorkingDirectory=/home/ec2-user/Git\nExecStart=gunicorn --bind 0.0.0.0:5000 app:app &\nRestart=always\n\n[Install]\nWantedBy=multi-user.target" > /etc/systemd/system/flaskapp.service
sudo systemctl daemon-reload
sudo systemctl start flaskapp.service
sudo systemctl enable flaskapp.service
')

echo "Instance created with ID: $new_instance"
#waits for the instance to run before procceding 
aws ec2 wait instance-running --instance-ids "$new_instance"
echo "Instance $new_instance is runnning..."
#checks for the Git direcotory to make sure the Git repo in ready
while [ ! -d "/home/ec2-user/Git" ]; do
    sleep 5
done

echo "Git clone is completed into /home/ec2-user/Git"

# Generate a timestamp for unique identifier
timestamp=$(date +"%Y%m%d%H%M%S")

#gives the AMI a unique name to avoid same name errors
ami_name="update-$timestamp"
#creats the AMI from the created instance and gives it the unique name 
aws ec2 create-image --instance-id "$new_instance" --name "$ami_name" --description "AMI update for flask"
echo "creating AMI $ami_name..."

#ami_id get the ID of the new AMI by filtering all the AMI'S and waits for the AMI to be completed before procceding
ami_id=$(aws ec2 describe-images --filters "Name=name,Values=$ami_name" --query 'Images[0].ImageId' --output text)
aws ec2 wait image-available --image-ids "$ami_id"
echo "AMI is now available: $ami_name"

#kills the instance leaving only the AMI availble 
aws ec2 terminate-instances --instance-ids "$new_instance"
echo "deleted the mechince with the ID of: $new_instance"

fi
