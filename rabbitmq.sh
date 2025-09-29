#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$LOGS_FOLDER
mkdir -p $LOGS_FOLDER
SCRIPT_DIR=$(PWD)
echo "Script started executed at: $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root privilege $N"
    exit 1 # failure is other than 0
fi

VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e " $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e " $2 ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding RabbitMQ repo"
dnf install rabbitmq-server -y
VALIDATE $? "Installing RabbitMQ Server"
systemctl enable rabbitmq-server
VALIDATE $? "Enabling RabbitMQ Server"
systemctl start rabbitmq-server
VALIDATE $? "Starting RabbitMQ"
rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Setting up permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"