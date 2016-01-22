#!/bin/bash

### SIP UAS

# Deploy
echo -e "\nDeploy SIP UAS Example\n"
cd $HOME/examples/sip-uas
ant deploy-all
sleep 10

echo -e "\nTesting SIP UAS Example"

echo -e "\nStart Single Test\n"
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
echo -e "SIP UAS Simple Test result: $SIP_UAS_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Single test"

echo -e "\nStart Performance Test\n"
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
echo -e "SIP UAS Performance Test result: $SIP_UAS_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"

# Undeploy
echo -e "\nUndeploy SIP UAS Example\n"
cd ..
ant undeploy-all
sleep 10
