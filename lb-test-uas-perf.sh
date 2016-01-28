#!/bin/bash
#export JSLEE=/opt/mobicents/mobicents-slee-2.8.14.40
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
#export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"
#export SIPP=$PWD/sipp

#export LB_VERSION=2.0.17
rm -rf logs
mkdir logs

#export JAVA_OPTS="-Xms2048m -Xmx2048m -XX:PermSize=512M -XX:MaxPermSize=1024M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false"
java $JAVA_OPTS -DlogConfigFile=$LBTEST/lb-log4j.xml -jar $LOADBALANCER/sip-balancer-jar-*-jar-with-dependencies.jar -mobicents-balancer-config=$LBTEST/lb-configuration.properties &
export LB_PID="$!"
echo "Load Balancer: $LB_PID"

sleep 10

$JBOSS_HOME/bin/run.sh -c port-1 -Djboss.service.binding.set=ports-01 -Djboss.messaging.ServerPeerID=0 -Dsession.serialization.jboss=false > $LOGS/lb-port-1-jboss.log 2>&1 &
export NODE1_PID="$!"
echo "NODE1: $NODE1_PID"

sleep 5

$JBOSS_HOME/bin/run.sh -c port-2 -Djboss.service.binding.set=ports-02 -Djboss.messaging.ServerPeerID=1 -Dsession.serialization.jboss=false > $LOGS/lb-port-2-jboss.log 2>&1 &
export NODE2_PID="$!"
echo "NODE2: $NODE2_PID"

sleep 60

echo "LB and Cluster are ready!"

echo -e "\nStart Performance Test\n"
cd $JSLEE/examples/sip-uas/sipp
$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 100 -rp 60s -m 100 -l 100 -bg

UAC_PID=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit -1
fi
echo "UAC_PID: $UAC_PID"

#sleep 210s
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then
    break
  fi
done

SIP_UAS_PERF_EXIT=$?
echo -e "SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n"
echo -e "SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"

sleep 15

pkill -TERM -P $NODE1_PID
pkill -TERM -P $NODE2_PID
kill -9 $LB_PID
