#!/bin/bash

### SIP B2BUA DIALOG
echo -e "\nTesting SIP B2BUA DIALOG Example"
cd $HOME/examples/sip-b2bua

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
