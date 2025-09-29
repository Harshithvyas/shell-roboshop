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
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

mkdir -p /app
VALIDATE $? "Creating app directory"

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

#### MongoDB setup ####
tee /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF &>>$LOG_FILE
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
VALIDATE $? "Add MongoDB 7 repo"

dnf install -y mongodb-org &>>$LOG_FILE
VALIDATE $? "Install MongoDB 7"

systemctl enable mongod &>>$LOG_FILE
systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Start MongoDB service"

#### Load catalogue data ####
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "Load catalogue products"

#### Start catalogue service ####
systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarted catalogue service"
