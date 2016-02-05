#!/bin/bash
#export JSLEE=/opt/mobicents/mobicents-slee-2.8.14.40
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
#export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"
#export SIPP=$PWD/sipp

#export LBVERSION=2.0.17
#rm -rf logs
#mkdir logs

export SUCCESS=0

export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false"
java $JAVA_OPTS -DlogConfigFile=$LBTEST/lb-log4j.xml -jar $LBPATH/sip-balancer-jar-$LBVERSION-jar-with-dependencies.jar -mobicents-balancer-config=$LBTEST/lb-configuration.properties &
export LB_PID="$!"
echo "Load Balancer: $LB_PID"

echo "Waiting 10 seconds"
sleep 10

$JBOSS_HOME/bin/run.sh -c port-1 -Djboss.service.binding.set=ports-01 -Djboss.messaging.ServerPeerID=0 -Dsession.serialization.jboss=false > $LOG/lb-port-1-jboss.log 2>&1 &
export NODE1_PID="$!"
echo "NODE1: $NODE1_PID"

echo "Waiting 10 seconds"
sleep 10

$JBOSS_HOME/bin/run.sh -c port-2 -Djboss.service.binding.set=ports-02 -Djboss.messaging.ServerPeerID=1 -Dsession.serialization.jboss=false > $LOG/lb-port-2-jboss.log 2>&1 &
export NODE2_PID="$!"
echo "NODE2: $NODE2_PID"

echo "Waiting 60 seconds"
sleep 60

echo "LB and Cluster are ready!"

echo -e "\nStart B2BUA Functionality Test\n"

cd $JSLEE/examples/sip-b2bua/sipp

$SIPP -trace_err -sf uas_DIALOG.xml -i 127.0.0.1 -p 5090 -r 1 -m 10 -l 100 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_DIALOG.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_DIALOG.xml -i 127.0.0.1 -p 5050 -r 1 -m 10 -l 100 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_DIALOG.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  
  TEST=$(ps aux | grep '[u]as_DIALOG.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    export SUCCESS=1
    break
  fi
done

SIP_B2BUA_DIALOG_EXIT=$?
echo -e "SIP B2BUA DIALOG Functionality Test result: $SIP_B2BUA_DIALOG_EXIT for $TIME seconds\n"
echo -e "SIP B2BUA DIALOG Functionality Test result: $SIP_B2BUA_DIALOG_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Functionality test"

echo "Waiting 10 seconds"
sleep 10

pkill -TERM -P $NODE1_PID
echo "Waiting 10 seconds"
sleep 10

pkill -TERM -P $NODE2_PID
echo "Waiting 10 seconds"
sleep 10

kill -9 $LB_PID
echo "Waiting 10 seconds"
sleep 10

exit $SUCCESS
