#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.harshithdaws86s.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MYSQL_HOST=mysql.harshithdaws86s.fun

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

dnf install python3 gcc python3-deve1 -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating system user"
else
  echo "roboshop user already exists" &>>$LOG_FILE
  echo -e " Creating system user ... $G SUCCESS $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading payment application"

cd /app
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment"

pip3 install -r requirements.txt &>>$LOG_FILE

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
systemctl daemon-reload
systemctl enable payment &>>$LOG_FILE

systemctl restart payment