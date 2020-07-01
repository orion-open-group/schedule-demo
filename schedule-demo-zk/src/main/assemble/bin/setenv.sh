#!/bin/sh


# set env
BACKUPDIR=schedule
APP_NAME=schedule-simpletask-test
LOGDIR=/data/logs/$APP_NAME

APP_LISTEN_HTTP_PORT=8015
JMX_PORT=9063

RUN_ENVIRONMENT="prod"
START_TIME=30
TARGET_VERSION=1.8