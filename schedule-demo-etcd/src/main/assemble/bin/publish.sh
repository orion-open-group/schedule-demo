#!/bin/sh

cd `dirname $0`

. ./setenv.sh

time=$(date "+%Y%m%d")

basepath=`pwd`

reg="/data/projects/backup.*"
if [[ "$basepath" =~ $reg ]];then
   echo "you can't re deploy on deployed folder"
   exit 1;
fi
#create dir to save the execute file
$(mkdir -p /data/projects/backup/$time)

if [  -d "/data/projects/${APP_NAME}" ];then
    cp -rf /data/projects/${APP_NAME} /data/projects/backup/$time/
fi
if [ ! -d "/data/projects/${APP_NAME}" ];then
    mkdir -p /data/projects/${APP_NAME}
fi

## clean the projects old file

rm -rf /data/projects/${APP_NAME}/*

cp -rf $basepath/* /data/projects/${APP_NAME}

cd /data/projects/${APP_NAME}

. ./server-ctl.sh $*
