#!/bin/bash

### SIP B2BUA

# Deploy
echo -e "\nDeploy SIP B2BUA Example\n"
cd $HOME/examples/sip-b2bua
ant deploy-all
sleep 10

### SIP B2BUA DIALOG
echo -e "\nTesting SIP B2BUA DIALOG Example"

echo -e "\nStart Single Test\n"

cd sipp
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
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_DIALOG.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_DIALOG_EXIT=$?
echo -e "SIP B2BUA DIALOG Single Test result: $SIP_B2BUA_DIALOG_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Single test"

echo -e "\nStart Performance Test\n"

$SIPP -trace_err -sf uas_DIALOG.xml -i 127.0.0.1 -p 5090 -r 400 -rp 85s -m 500 -l 400 -bg
#$SIPP -trace_err -sf uas_DIALOG.xml -i 127.0.0.1 -p 5090 -r 10 -m 500 -l 400 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_DIALOG.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_DIALOG.xml -i 127.0.0.1 -p 5050 -r 400 -rp 85s -m 500 -l 400 -bg
#$SIPP 127.0.0.1:5060 -trace_err -sf uac_DIALOG.xml -i 127.0.0.1 -p 5050 -r 10 -m 500 -l 400 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_DIALOG.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_DIALOG.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_DIALOG_PERF_EXIT=$?
echo -e "SIP B2BUA DIALOG Performance Test result: $SIP_B2BUA_DIALOG_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"
###

sleep 30

### SIP B2BUA CANCEL
echo -e "\nTesting SIP B2BUA CANCEL Example"

echo -e "\nStart Single Test\n"

cp $LOG/siptests-jboss.log $LOG/out-b2bua-cancel-0.log

#cd sipp
$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 1 -m 10 -l 100 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 1 -m 10 -l 100 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_CANCEL.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_CANCEL_EXIT=$?
echo -e "\nSIP B2BUA CANCEL Single Test result: $SIP_B2BUA_CANCEL_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Single test"

diff $LOG/out-b2bua-cancel-0.log $LOG/siptests-jboss.log > $LOG/out-b2bua-cancel.simple.log
ERRCOUNT=$(grep -ic " error " $LOG/out-b2bua-cancel.simple.log)
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-b2bua-cancel.simple.log\n" >> $REPORT
else
  rm -f $LOG/out-b2bua-cancel.simple.log
fi

echo -e "\nStart Performance Test\n"
cp $LOG/siptests-jboss.log $LOG/out-b2bua-cancel-0.log

$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 10 -m 500 -l 400 -bg
#$SIPP -trace_err -sf uas_CANCEL.xml -i 127.0.0.1 -p 5090 -r 400 -rp 85s -m 500 -l 400 -bg
#UAS_PID=$!
UAS_PID=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
if [ "$UAS_PID" == "" ]; then
  exit -1
fi
echo "UAS: $UAS_PID"

sleep 1
$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 10 -m 500 -l 400 -bg
#$SIPP 127.0.0.1:5060 -trace_err -sf uac_CANCEL.xml -i 127.0.0.1 -p 5050 -r 400 -rp 85s -m 500 -l 400 -bg
#UAC_PID=$!
UAC_PID=$(ps aux | grep '[u]ac_CANCEL.xml' | awk '{print $2}')
if [ "$UAC_PID" == "" ]; then
  exit
fi
echo "UAC: $UAC_PID"

#sleep 120s
TIME=0
while :; do
  sleep 1
  TIME=$((TIME+1))
  TEST=$(ps aux | grep '[u]as_CANCEL.xml' | awk '{print $2}')
  if [ "$TEST" != "$UAS_PID" ]; then
    break
  fi
done

SIP_B2BUA_CANCEL_PERF_EXIT=$?
echo -e "\nSIP B2BUA CANCEL Performance Test result: $SIP_B2BUA_CANCEL_PERF_EXIT for $TIME seconds\n" >> $REPORT
echo -e "\nFinish Performace test"

diff $LOG/out-b2bua-cancel-0.log $LOG/siptests-jboss.log > $LOG/out-b2bua-cancel.perf.log
ERRCOUNT=$(grep -ic " error " $LOG/out-b2bua-cancel.perf.log)
if [ "$ERRCOUNT" != 0 ]; then
  echo -e "    There are $ERRCOUNT errors. See ERRORs in test-logs/out-b2bua-cancel.perf.log\n" >> $REPORT
else
  rm -f $LOG/out-b2bua-cancel.perf.log
fi
###

sleep 30

# Undeploy
echo -e "\nUndeploy SIP B2BUA Example\n"
cd ..
ant undeploy-all
sleep 10

rm -f $LOG/$LOG/out-*-0.log
