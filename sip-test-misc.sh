#!/bin/bash

### SIP Wake Up

# Deploy
echo -e "\nDeploy SIP Wake Up Example\n"
cd $JSLEE_HOME/examples/sip-wake-up
ant deploy-all
echo "Wait 10 seconds.."
sleep 10

echo -e "\nTesting SIP Wake Up Example"
# error handling
cp $LOG/sip-jboss.log $LOG/temp-wakeup-0.log

cd sipp
$SIPP 127.0.0.1:5060 -sf scenario.xml -i 127.0.0.1 -p 5050 -r 10 -m 10 -bg

UAC_PID=$(ps aux | grep '[s]cenario.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then exit -1; fi
echo "UAC_PID: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[s]cenatio.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then break; fi
done

SIP_WAKEUP_EXIT=$?
echo -e "    SIP Wake Up Test result: $SIP_WAKEUP_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish test"


# error handling
diff $LOG/temp-wakeup-0.log $LOG/sip-jboss.log > $LOG/temp-wakeup.simple.log
ERRCOUNT=$(grep -ic " error " $LOG/temp-wakeup.simple.log)
SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "        There are $ERRCOUNT errors. See ERRORs in test-logs/out-wakeup.simple.log\n" >> $REPORT
else
  echo "There are no errors."
  rm -f $LOG/temp-wakeup.simple.log
fi
# error handling


# Undeploy
echo -e "\nUndeploy SIP Wake Up Example\n"
cd ..
ant undeploy-all
echo "Wait 60 seconds.."
sleep 60

### SIP JDBC Registrar

# Deploy
echo -e "\nDeploy SIP JDBC Registrar Example\n"
cd $JSLEE_HOME/examples/sip-jdbc-registrar
ant deploy-all
echo "Wait 15 seconds.."
sleep 15

# error handling
cp $LOG/sip-jboss.log $LOG/temp-jdbc-reg-0.log
cd sipp

echo -e "\nStart SIP Registrar Functionality Test\n"
$SIPP 127.0.0.1:5060 -sf registrar-functionality.xml -i 127.0.0.1 -p 5050 -r 1 -m 1 -bg

UAC_PID=$(ps aux | grep '[r]egistrar-functionality' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then exit -1; fi
echo "UAC_PID: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[r]egistrar-functionality' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then break; fi
done

SIP_REGFUNC_EXIT=$?
echo -e "    SIP Registrar Functionality Test result: $SIP_REGFUNC_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish test"
echo "Wait 15 seconds.."
sleep 15

# error handling
diff $LOG/temp-jdbc-reg-0.log $LOG/sip-jboss.log > $LOG/temp-jdbc-reg.simple.log
ERRCOUNT=$(grep -ic " error " $LOG/temp-jdbc-reg.simple.log)
SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "        There are $ERRCOUNT errors. See ERRORs in test-logs/out-jdbc-reg.simple.log\n" >> $REPORT
else
  echo "There are no errors."
  rm -f $LOG/temp-jdbc-reg.simple.log
fi
# error handling


echo -e "\nStart SIP Registrar Load Test\n"
# error handling
cp $LOG/sip-jboss.log $LOG/temp-jdbc-reg-1.log

$SIPP 127.0.0.1:5060 -sf registrar-load-test.xml -i 127.0.0.1 -p 5050 -r 1 -m 200 -bg

UAC_PID=$(ps aux | grep '[r]egistrar-load-test' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then exit -1; fi
echo "UAC_PID: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[r]egistrar-load-test' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then break; fi
done

SIP_REGLOAD_EXIT=$?
echo -e "    SIP Registrar Load Test result: $SIP_REGLOAD_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish test"
echo "Wait 15 seconds.."
sleep 15

# error handling
diff $LOG/temp-jdbc-reg-0.log $LOG/sip-jboss.log > $LOG/temp-jdbc-reg.perf.log
ERRCOUNT=$(grep -ic " error " $LOG/temp-jdbc-reg.perf.log)
SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "        There are $ERRCOUNT errors. See ERRORs in test-logs/out-jdbc-reg.perf.log\n" >> $REPORT
else
  echo "There are no errors."
  rm -f $LOG/temp-jdbc-reg.perf.log
fi
# error handling


# Undeploy
echo -e "\nUndeploy SIP JDBC Registrar Example\n"
cd ..
ant undeploy-all
echo "Wait 30 seconds.."
sleep 30