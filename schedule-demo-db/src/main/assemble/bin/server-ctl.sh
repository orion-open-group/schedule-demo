#!/usr/bin/env bash

ulimit -s 20480
export PATH=$PATH:/usr/sbin

. ./setenv.sh

# get dir and set java home
echo 'basepath:' ${basepath}

if [[ -d "${basepath}/jdk" ]]; then
  export JAVA_HOME=${basepath}/jdk
  export JRE_HOME=${JAVA_HOME}/jre
  export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
  export PATH=${JAVA_HOME}/bin:$PATH

  echo 'path:'$PATH
  echo 'java_home:'$JAVA_HOME
  echo 'jre_home:'$JRE_HOME
  echo 'classpath:'$CLASSPATH
fi

CURRENT_JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
echo 'using jdk version : ' ${CURRENT_JAVA_VERSION}

BASEDIR=`pwd`
echo "base dir is: $BASEDIR"
echo "base log dir is $LOGDIR/"
#STATUS_FILE=${PRGDIR}/status

PERM_SIZE=128
PERM_SIZE_MAX=256

USAGE()
{
  echo "usage: $0 start|stop|restart|status [-p|--http-port port] [-j|--jmx-port port] [-t|--start-timeout time] [-e|--environment environment] [additional jvm args]"
}

if [[ $# -lt 1 ]]; then
  USAGE
  exit -1
fi

CMD="$1"
shift

while true; do
  case "$1" in
    -p|--http-port) APP_LISTEN_HTTP_PORT="$2" ; shift 2;;
    -s|--https-port) APP_LISTEN_HTTPS_PORT="$2" ; shift 2;;
    -j|--jmx-port) JMX_PORT="$2" ; shift 2 ;;
    -l|--log-dir) LOGDIR="$2" ; shift 2 ;;
    -t|--start-timeout) START_TIME="$2" ; shift 2 ;;
    -e|--environment) RUN_ENVIRONMENT="$2" ; shift 2 ;;
    *) break ;;
  esac
done

PID_FILE=${BASEDIR}/PID_${APP_LISTEN_HTTP_PORT}
ADDITIONAL_OPTS=$*;

if [[ "$RUN_ENVIRONMENT" = "dev" ]] || [[ "$RUN_ENVIRONMENT" = "qa" ]]; then
  ENVIRONMENT_MEM="-Xms256m -Xmx512m -Xss256K -XX:MaxDirectMemorySize=256m"
else
  ENVIRONMENT_MEM="-Xms2048m -Xmx2048m -XX:MaxDirectMemorySize=2048m"
fi

# define GC log path
if [[ -d /dev/shm/ ]]; then
  GC_LOG_FILE=/dev/shm/gc-${APP_NAME}-${APP_LISTEN_HTTP_PORT}.log
else
  GC_LOG_FILE=${LOGDIR}/gc-${APP_NAME}-${APP_LISTEN_HTTP_PORT}.log
fi

# set GC_THREADS
GC_THREADS="-XX:ParallelGCThreads=8"
if [[ -n "$PARALLEL_GC_THREADS" ]]; then
  GC_THREADS="-XX:ParallelGCThreads=${PARALLEL_GC_THREADS}"
  if [[ -n "$CONC_GC_THREADS" ]]; then
    GC_THREADS="$GC_THREADS -XX:ConcGCThreads=${CONC_GC_THREADS}"
  fi
fi

JAVA_OPTS="-XX:+PrintCommandLineFlags -XX:-OmitStackTraceInFastThrow -XX:-UseBiasedLocking -XX:-UseCounterDecay -XX:AutoBoxCacheMax=20000 -XX:+PerfDisableSharedMem -Djava.security.egd=file:/dev/./urandom"
MEM_OPTS="-server ${ENVIRONMENT_MEM} -XX:NewRatio=1 -XX:MaxTenuringThreshold=2 -XX:+UseConcMarkSweepGC -XX:-CMSClassUnloadingEnabled -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UnlockDiagnosticVMOptions -XX:ParGCCardsPerStrideChunk=4096 -XX:+ParallelRefProcEnabled -XX:+ExplicitGCInvokesConcurrent -XX:+AlwaysPreTouch -XX:+PrintPromotionFailure ${GC_THREADS}"
GCLOG_OPTS="-Xloggc:${GC_LOG_FILE} -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCDateStamps -XX:+PrintGCDetails"
CRASH_OPTS="-XX:ErrorFile=${LOGDIR}/hs_err_%p.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${LOGDIR}/"
JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.ssl=false -Dsun.rmi.transport.tcp.threadKeepAliveTime=75000 -Djava.rmi.server.hostname=127.0.0.1"
OTHER_OPTS="-Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Dspring.profiles.active=$RUN_ENVIRONMENT -Dapp.log.dir=$LOGDIR -Dserver.port=$APP_LISTEN_HTTP_PORT"

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
JAVA_MINOR_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '_' '{print $2*1}')
# at least Java 1.7 required
if [[ "$JAVA_VERSION" < "1.7" ]]; then
  echo "Error: Unsupported the java version $JAVA_VERSION , please use the version $TARGET_VERSION and above."
  exit -1;
fi

if [[ "$JAVA_VERSION" < "1.8" ]]; then
  MEM_OPTS="$MEM_OPTS -XX:PermSize=${PERM_SIZE}m -XX:MaxPermSize=${PERM_SIZE_MAX}m -XX:ReservedCodeCacheSize=96M"
  if [[ ${JAVA_MINOR_VERSION} -ge 79 ]]; then
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCCause -XX:+CMSParallelInitialMarkEnabled"
  else
    JAVA_OPTS="$JAVA_OPTS -XX:+PrintGCApplicationConcurrentTime"
  fi
else
  MEM_OPTS="$MEM_OPTS -XX:MetaspaceSize=${PERM_SIZE}m -XX:MaxMetaspaceSize=${PERM_SIZE_MAX}m -XX:ReservedCodeCacheSize=96M -XX:-TieredCompilation"
  if [[ ${JAVA_MINOR_VERSION} -ge 11 ]]; then
    JAVA_OPTS="$JAVA_OPTS -XX:+CMSParallelInitialMarkEnabled"
  fi
fi

BACKUP_GC_LOG()
{
  GCLOG_DIR=${LOGDIR}
  BACKUP_FILE="${GCLOG_DIR}/gc-${APP_NAME}-${APP_LISTEN_HTTP_PORT}_$(date +'%Y%m%d_%H%M%S').log"

  if [[ -f ${GC_LOG_FILE} ]]; then
    echo "saving gc log ${GC_LOG_FILE} to ${BACKUP_FILE}"
    mv ${GC_LOG_FILE} ${BACKUP_FILE}
  fi
}

GET_PID_BY_ALL_PORT()
{
  echo `lsof -n -P -i :${APP_LISTEN_HTTP_PORT},${JMX_PORT} | grep LISTEN | awk '{print $2}' | head -n 1`
}

CHECK_PID_EXISTS()
{
  echo `ps -p $PID | grep $PID | head -n 1`
}

CHECK_PORT()
{
  netstat -an | grep "$APP_LISTEN_HTTP_PORT\|$JMX_PORT" | grep -i "listen" | grep -v grep
}

STOP()
{
  BACKUP_GC_LOG

  if [[ -f $PID_FILE ]] ; then
	PID=`cat $PID_FILE`
  else
    PID=$(GET_PID_BY_ALL_PORT)
  fi
  echo "pid is: $PID"
  if [[ "$PID" != "" ]] ; then
	if [[ -d /proc/$PID ]] || [[ "$(CHECK_PID_EXISTS)" != "" ]] ; then
	  #LISTEN_STATUS=`cat ${STATUS_FILE}`
	  echo "$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME stopping."
	  kill $PID

	  if [[ x"$PID" != x ]]; then
	    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME still running as process:$PID...\c"
	  fi
      # wait for process to exit
	  while  [[ -d /proc/$PID ]] || [[ "$(CHECK_PID_EXISTS)" != "" ]]; do
	    echo -e ".\c"
	    sleep 1
	  done

	  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME stop successfully"
	  if [[ -f $PID_FILE ]] ; then
	    rm $PID_FILE
      fi
	  sleep 1
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME is not running or pid in pid file($PID_FILE) is not correct."
    fi
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME is not running."
  fi
}

START()
{
  echo "active profile is: $RUN_ENVIRONMENT, log dir is: $LOGDIR"
  # check memory size
  if [[ 0"$SYS_MEM" != "0" && SYS_MEM -lt 1024 ]]; then
    echo -e  "\033[31m Error: memory can not less than 1024 MB , The current memory size is $SYS_MEM MB \033[0m"
    exit -1
  fi

  BACKUP_GC_LOG

  if [[ -f $PID_FILE ]] ; then
	PID=`cat $PID_FILE`
  fi
  if [[ "$PID" != "" ]]
	then
	if [[ -d /proc/$PID ]] || [[ "$(CHECK_PID_EXISTS)" != "" ]] ; then
	 echo -e "\033[31m  $APP_NAME is running, please stop it first!! \033[0m"
	 exit -1
	fi
  fi

  if [[ ! -d "$LOGDIR" ]]; then
    echo "Warning! The log dir: $LOGDIR not existed! Trying to create log dir automatically."
    mkdir -p "$LOGDIR"
    if [[ -d "$LOGDIR" ]]; then
      echo "Creat log dir: $LOGDIR success!"
    else
      echo -e "\033[31m Create log dir: $LOGDIR failed, please check it! \033[0m"
      exit -1
    fi
  fi

  LISTEN_STATUS="$APP_NAME http port is ${APP_LISTEN_HTTP_PORT}, JMX port is ${JMX_PORT}"
  echo "$APP_NAME starting, ${LISTEN_STATUS}."
  nohup java $JAVA_OPTS $MEM_OPTS $GCLOG_OPTS $JMX_OPTS $CRASH_OPTS $OTHER_OPTS $ADDITIONAL_OPTS -jar $BASEDIR/${APP_NAME}*.jar >> $LOGDIR/${APP_NAME}.out 2>&1 &
  PID=$!
  echo $PID > $PID_FILE
  sleep 3

  #903 "if[ ! -d /proc/$PID ]" will not evaluate correctly on MACOS, change to "if ! ps -p $PID > /dev/null";
  if ! ps -p $PID > /dev/null; then
 	echo -e "\n ${APP_NAME}.out last 10 lines  is :"
    tail -10 ${LOGDIR}/${APP_NAME}.out
    echo -e "\033[31m \n$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME start may be unsuccessful, process exited immediately after starting, might be JVM parameter problem or JMX port occupation! See ${LOGDIR}/${APP_NAME}.out for more information. \033[0m"
    exit -1
  fi

  starttime=0
  while  [[ x"$(CHECK_PORT)" == x ]]; do
    if [[ "$starttime" -lt ${START_TIME} ]]; then
      sleep 1
      ((starttime++))
      echo -e ".\c"
    else
	  echo -e "\n ${APP_NAME}.out last 10 lines  is :"
      tail -10 ${LOGDIR}/${APP_NAME}.out
	  echo -e "\033[31m \n$(date '+%Y-%m-%d %H:%M:%S') $APP_NAME start maybe unsuccess, start checking not finished until reach the starting timeout! See ${LOGDIR}/${APP_NAME}.out for more information. \033[0m"
      exit -1
    fi
  done

  echo "$APP_NAME start successfully, running as process: $PID"
  echo "pid file is $PID_FILE"
}

STATUS()
{
  if [[ -f $PID_FILE ]] ; then
	PID=`cat $PID_FILE`
  fi
  if [[ "$PID" != "" ]] ; then
	if [[ -d /proc/$PID ]] || [[ "$(CHECK_PID_EXISTS)" != "" ]] ; then
	  echo "$APP_NAME is running, PID is ${PID}, port is ${APP_LISTEN_HTTP_PORT}"
	  exit 0
	else
	  echo "$APP_NAME is not running, but PID file exists, please remove it."
	fi
  fi
  echo "$APP_NAME is not running."
}

case "$CMD" in
  stop) STOP;;
  start) START;;
  restart) STOP;sleep 10;START;;
  status) STATUS;;
  help) USAGE;;
  *) USAGE;;
esac
