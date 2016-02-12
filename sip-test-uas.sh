#!/bin/bash

### SIP UAS

# Deploy
echo -e "\nDeploy SIP UAS Example\n"
cd $JSLEE_HOME/examples/sip-uas
ant deploy-all
echo "Wait 10 seconds.."
sleep 10

echo -e "\nTesting SIP UAS Example"

echo -e "\nStart Single Test\n"
# error handling
cp $LOG/sip-jboss.log $LOG/temp-uas-0.log
cd sipp

$SIPP 127.0.0.1:5060 -inf users.csv -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 1 -m 10 -l 100 -bg

UAC_PID=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then exit -1; fi
echo "UAC_PID: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then break; fi
done

SIP_UAS_EXIT=$?
echo -e "    SIP UAS Simple Test result: $SIP_UAS_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Single test"


# error handling
diff $LOG/temp-uas-0.log $LOG/sip-jboss.log > $LOG/temp-uas.simple.log
ERRCOUNT=$(grep -ic " error " $LOG/temp-uas.simple.log)
SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "        There are $ERRCOUNT errors. See ERRORs in test-logs/out-uas.simple.log\n" >> $REPORT
else
  echo "There are no errors."
  rm -f $LOG/temp-uas.simple.log
fi
# error handling


echo -e "\nStart Performance Test\n"
# error handling
cp $LOG/sip-jboss.log $LOG/temp-uas-1.log

$SIPP 127.0.0.1:5060 -inf users.csv -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 1000 -rp 90s -m 1200 -l 1000 -bg
#$SIPP 127.0.0.1:5060 -inf users.csv -trace_err -sf uac.xml -i 127.0.0.1 -p 5050 -r 50 -m 1200 -l 1000 -bg

UAC_PID=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit -1
fi
echo "UAC_PID: $UAC_PID"

#sleep 210s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]ac.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAC_PID" ]; then
    break
  fi
done

SIP_UAS_PERF_EXIT=$?
echo -e "    SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"


# error handling
diff $LOG/temp-uas-1.log $LOG/sip-jboss.log > $LOG/temp-uas.perf.log
ERRCOUNT=$(grep -ic " error " $LOG/temp-uas.perf.log)
SIP_ERRCOUNT=$((SIP_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "        There are $ERRCOUNT errors. See ERRORs in test-logs/out-uas.perf.log\n" >> $REPORT
else
  echo "There are no errors."
  rm -f $LOG/temp-uas.perf.log
fi
# error handling

# Undeploy
echo -e "\nUndeploy SIP UAS Example\n"
cd ..
ant undeploy-all
echo "Wait 10 seconds.."
sleep 10