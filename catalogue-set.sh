#!/bin/bash

set -euo pipefail

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
MONGODB_HOST=mongodb.harshithdaws86s.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" &>>$LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R ERROR:: Please run this script with root privilege $N"
    exit 1
fi

VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e " $2 ... $G SUCCESS $N" | tee -a $LOG_FILE
  else
    echo -e " $2 ... $R FAILURE $N" | tee -a $LOG_FILE
    exit 1
  fi
}

#### Nodejs ####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"
dnf install nodejs -y &>>$LOG_FILE 
VALIDATE $? "Installing NodeJS 20"

#### System user and app directory ####
mkdir -p /app
VALIDATE $? "Creating app directory"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating system user"
else
  echo "roboshop user already exists" &>>$LOG_FILE
  echo -e " Creating system user ... $G SUCCESS $N"
fi

#### Download and setup catalogue ####
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"
cd /app
VALIDATE $? "Changing to app directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzip catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"
cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue service"

#### MongoDB client setup ####
dnf install -y mongodb-mongosh &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"

#### Load catalogue data ####
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"

#### Start catalogue service ####
systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarted catalogue service"
