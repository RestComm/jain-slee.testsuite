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

#echo "Waiting 240 seconds"
#sleep 240

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"  
  STARTED_IN_1=$(grep -c " Started in " $LOG/lb-port-1-jboss.log)
  STARTED_IN_2=$(grep -c " Started in " $LOG/lb-port-2-jboss.log)
  if [ $((STARTED_IN_1+STARTED_IN_2)) == 2 ]; then break; fi
done
#sleep 60

echo "LB and Cluster are ready!"

echo -e "\nStart UAS Performance Test\n"

#cp $LOG/load-balancer.log $LOG/out-load-balancer-uas-0.log
#cp $LOG/lb-port-1-jboss.log $LOG/out-port-1-uas-0.log
#cp $LOG/lb-port-2-jboss.log $LOG/out-port-2-uas-0.log

cd $JSLEE/examples/sip-uas/sipp
#$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 600 -rp 60s -m 800 -l 1000 -bg
$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 3 -m 200 -l 1000 -bg

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
  
  #echo $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log
  
  # error handling
  if [ -f $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log ]; then
    export SUCCESS=0
    echo -e "    There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n"
    echo -e "    There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n" >> $REPORT
  #  kill -9 $UAC_PID
  #  break
  fi
  
  #diff $LOG/out-load-balancer-uas-0.log $LOG/load-balancer.log > $LOG/out-$TIME.lbuas.log
  #diff $LOG/out-port-1-uas-0.log $LOG/lb-port-1-jboss.log >> $LOG/out-$TIME.lbuas.log
  #diff $LOG/out-port-2-uas-0.log $LOG/lb-port-2-jboss.log >> $LOG/out-$TIME.lbuas.log
  
  #ERRCOUNT=$(grep -ic " error " $LOG/out-$TIME.lbuas.log)
  #SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
  #if [ "$ERRCOUNT" != 0 ]; then
  #  export SUCCESS=0
  #  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-TIME.lbuas.log\n"
  #  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-TIME.lbuas.log\n" >> $REPORT
  #  kill -9 $UAC_PID
  #  break
  #else
  #  echo "Nothing"
  #  #rm -f $LOG/out-*.lbuas.log
  #fi
  # error handling
  
  
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then
    export SUCCESS=1
    break
  fi
done

SIP_UAS_PERF_EXIT=$?
echo -e "SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n"
echo -e "SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"

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