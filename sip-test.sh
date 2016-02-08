#!/bin/bash

export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
export REPORT=$REPORTS/siptests-report.log
export SIP_ERRCOUNT=0

export SIPP=$JSLEE_HOME/test-tools/sipp/sipp

# Start JSLEE
export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
echo $JBOSS_HOME

#rm -f $LOG/siptests-jboss.log
#rm -f $REPORT
#mkdir -p $LOG
#mkdir -p $REPORTS

$JBOSS_HOME/bin/run.sh > $LOG/siptests-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS_PID: $JBOSS_PID"

#sleep 120
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  STARTED_IN=$(grep -c " Started in " $LOG/siptests-jboss.log)
  if [ "$STARTED_IN" == 1 ]; then break; fi
done

echo -e "SIP Tests Report\n" >> $REPORT

#echo -e "Exit code:
#    0: All calls were successful
#    1: At least one call failed
#   97: exit on internal command. Calls may have been processed
#   99: Normal exit without calls processed
#   -1: Fatal error
#   -2: Fatal error binding a socket\n" >> $REPORT

# SIP UAS
./sip-test-uas.sh

# SIP B2BUA

# Deploy
echo -e "\nDeploy SIP B2BUA Example\n"
cd $JSLEE_HOME/examples/sip-b2bua
ant deploy-all
echo "Waiting 10 seconds"
sleep 10

cd $JSLEE_HOME
./sip-test-b2bua-dialog.sh
./sip-test-b2bua-cancel.sh

# Undeploy
echo -e "\nUndeploy SIP B2BUA Example\n"
cd $JSLEE_HOME/examples/sip-b2bua
ant undeploy-all
echo "Waiting 10 seconds"
sleep 10

cd $JSLEE_HOME
# SIP Wake Up
# SIP JDBC Registrar
./sip-test-misc.sh

export SUCCESS=0
echo -e "\nCommon result:  $SIP_ERRCOUNT error(s)\n" >> $REPORT
if [ "$SIP_ERRCOUNT" == 0 ]
then
  export SUCCESS=1
fi

#rm -f $LOG/out-*-0.log
#rm -f $LOG/out-*-1.log

pkill -TERM -P $JBOSS_PID
echo "Waiting 10 seconds"
sleep 10

exit $SUCCESS
