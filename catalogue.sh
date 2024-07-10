#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGDB_HOST=mongodb.ramya.website

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

echo "script started executing at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 # you can give other than 0
else
    echo "You are root user"
fi # fi means reverse of if, indicating condition end

dnf module disable nodejs -y

VALIDATE $? "disabling old nodejs"

dnf module enable nodejs:18 -y

VALIDATE $? "enabling nodejs"

dnf install nodejs -y

VALIDATE $? "installing nodejs"

id roboshop #if roboshop user does not exist, then it is failure
if [ $? -ne 0 ]
then
    useradd roboshop
    VALIDATE $? "roboshop user creation"
else
    echo -e "roboshop user already exist $Y SKIPPING $N"
fi

mkdir -p /app

VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip

VALIDATE $? "downloading catalogue file"

cd /app 

VALIDATE $? "redirecteing to app directory"

unzip /tmp/catalogue.zip

VALIDATE $? "unzip files"

npm install 

VALIDATE $? "installing npm"

cp /home/centos/shellscript-roboshop/catalogue.service /etc/systemd/system/catalogue.service

VALIDATE $? "copying catalogue files"

systemctl daemon-reload &>> $LOGFILE

systemctl enable catalogue

VALIDATE $? "Enable catalogue"

systemctl start catalogue

VALIDATE $? "Enable catalogue"

cp /home/centos/shellscript-roboshop/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE

VALIDATE $? "copying mongodb repo"

dnf install mongodb-org-shell -y

VALIDATE $? "Installing MongoDB client"

mongo --host $MONGDB_HOST </app/schema/catalogue.js &>> $LOGFILE

VALIDATE $? "Loading catalouge data into MongoDB"