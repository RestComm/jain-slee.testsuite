#!/bin/bash

export START=1
export SUCCESS=0

echo -e "\nUAS Performance Test\n"
echo -e "Start Load Balancer and Cluster\n"

export JAVA_OPTS="-Xms512m -Xmx512m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false"
java $JAVA_OPTS -DlogConfigFile=$LBTEST/lb-log4j.xml -jar $LBPATH/sip-balancer-jar-*-jar-with-dependencies.jar -mobicents-balancer-config=$LBTEST/lb-configuration.xml &
export LB_PID="$!"
echo "Load Balancer: $LB_PID"
echo "Wait 10 seconds.."
sleep 10
export JAVA_OPTS=""

export JBOSS_HOME=$SERVER1_HOME
sh $SERVER1_HOME/bin/standalone.sh --server-config=standalone-ha.xml -b 127.0.0.1 -bmanagement=127.0.0.1 > $LOG/lb-uas-load-port-1-jboss.log 2>&1 &
export NODE1_PID="$!"
echo "NODE1: $NODE1_PID"

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo " .. $TIME seconds"
  STARTED_IN_1=$(grep -c " started in " $LOG/lb-uas-load-port-1-jboss.log)
  if [ "$STARTED_IN_1" == 1 ]; then break; fi
  
  if [ $TIME -gt 300 ]; then
    export START=0
    break
  fi
done

if [ "$START" -eq 0 ]; then
  echo "There is a problem with starting Load Balancer and Cluster!"
  echo "Wait 10 seconds.."
  
  pkill -TERM -P $NODE1_PID
  sleep 10
  
  kill $LB_PID
  wait $LB_PID 2>/dev/null
  exit $SUCCESS
fi

cp $SERVER1/sip11-ra-DU-*.jar $SERVER1_HOME/standalone/deployments
sleep 10

export JBOSS_HOME=$SERVER2_HOME
sh $SERVER2_HOME/bin/standalone.sh --server-config=standalone-ha.xml -b 127.0.0.2 -bmanagement=127.0.0.2 > $LOG/lb-uas-load-port-2-jboss.log 2>&1 &
export NODE2_PID="$!"
echo "NODE2: $NODE2_PID"

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo " .. $TIME seconds"
  STARTED_IN_2=$(grep -c " started in " $LOG/lb-uas-load-port-2-jboss.log)
  if [ "$STARTED_IN_2" == 1 ]; then break; fi
  
  if [ $TIME -gt 300 ]; then
    export START=0
    break
  fi
done

cp $SERVER2/sip11-ra-DU-*.jar $SERVER2_HOME/standalone/deployments
sleep 10

if [ "$START" -eq 1 ]; then
  echo "Load Balancer and Cluster are ready!"
else
  echo "There is a problem with starting Load Balancer and Cluster!"
  echo "Wait 20 seconds.."
    
  pkill -TERM -P $NODE1_PID
  sleep 10
  pkill -TERM -P $NODE2_PID
  sleep 10
  
  kill $LB_PID
  wait $LB_PID 2>/dev/null
  exit $SUCCESS
fi

export JBOSS_HOME=$JBOSS_HOME

####

echo -e "\nStart UAS Performance Test\n"
echo -e "    UAS Performance Test is Started\n" >> $REPORT

cd $JSLEE/examples/sip-uas/sipp
$SIPP 127.0.0.1:5060 -inf users.csv -nd -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 10 -m 700 -l 1000 -bg

ps aux | grep '[u]ac.xml'

UAC_PID=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit -1
fi
echo "UAC_PID: $UAC_PID"

export START=1
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then
    export SUCCESS=1
    break
  fi

done

if [ "$START" -eq 0 ]; then
  echo "There is a problem with executing SIPP!"
  echo "Wait 20 seconds.."
    
  pkill -TERM -P $NODE1_PID
  sleep 10
  pkill -TERM -P $NODE2_PID
  sleep 10
  
  kill $LB_PID
  wait $LB_PID 2>/dev/null
  exit $SUCCESS
fi

# error handling
if [ -f $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log ]; then
  NUMOFLINES=$(wc -l < $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log)
  WATCHDOG=$(grep -c "Overload warning: the minor watchdog timer" $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log)
  TEST=$((NUMOFLINES-1-WATCHDOG))
  if [ "$TEST" -gt 0 ]
  then
    export SUCCESS=0
    echo "WATCHDOG: $WATCHDOG of NUMOFLINES: $NUMOFLINES"
    echo -e "There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n"
    echo -e "        There are errors. See ERRORs in $JSLEE/examples/sip-uas/sipp/uac_"$UAC_PID"_errors.log\n" >> $REPORT
  fi
fi

SIP_UAS_PERF_EXIT=$?
echo -e "UAS Performance Test is Finished: $SIP_UAS_PERF_EXIT for $TIME seconds\n"
echo -e "    UAS Performance Test is Finished: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT

echo "Stopping Cluster nodes and Load Balancer."
echo "Wait 20 seconds.."

pkill -TERM -P $NODE1_PID
sleep 20
rm $SERVER1_HOME/standalone/deployments/sip11-ra-DU-*.jar
pkill -TERM -P $NODE2_PID
sleep 20
rm $SERVER2_HOME/standalone/deployments/sip11-ra-DU-*.jar

kill $LB_PID
wait $LB_PID 2>/dev/null

cd $LOG
find . -name 'load-balancer.log*' -exec bash -c 'mv $0 ${0/load-balancer/lb-uas-load-loadbalancer}' {} \;

exit $SUCCESS
