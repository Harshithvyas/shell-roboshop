#!/bin/bash

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

#### Nodejs ####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? " Enabling NodeJS 20"
dnf install nodejs -y &>>$LOG_FILE 
VALIDATE $? " Installing NodeJS 20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

mkdir /app
VALIDATE $? "Creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"
cd /app
VALIDATE $? "Changing to app directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"
npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"
cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copy systemctl service"
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copy mongo repo"
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install MongoDB client"
mongosh --host $MONGODB-HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"
systemctl restart catalogue
VALIDATE $? "Restarted catalogue"