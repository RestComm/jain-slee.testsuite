#!/bin/bash

export HOME=$PWD
export LOG=$HOME/test-logs
export REPORTS=$HOME/test-reports
#export SIPP=$HOME/test-tools/sipp/sipp
export SIPP=sipp

sipp -v
$SIPP -v

# Start JSLEE
export JBOSS_HOME=$HOME/jboss-5.1.0.GA
echo $JBOSS_HOME

rm -f $LOG/siptests-jboss.log
rm -f $REPORTS/siptests-report.log
mkdir -p $LOG
mkdir -p $REPORTS
$JBOSS_HOME/bin/run.sh > $LOG/siptests-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS_PID: $JBOSS_PID"

sleep 45

echo -e "SIP Tests Report\n" >> $REPORTS/siptests-report.log

echo -e "Exit code:
    0: All calls were successful
    1: At least one call failed
   97: exit on internal command. Calls may have been processed
   99: Normal exit without calls processed
   -1: Fatal error
   -2: Fatal error binding a socket\n" >> $REPORTS/siptests-report.log

# SIP UAS
./sip-test-uas.sh

# SIP B2BUA
./sip-test-b2bua.sh

# SIP Wake Up
# SIP JDBC Registrar

pkill -TERM -P $JBOSS_PID
