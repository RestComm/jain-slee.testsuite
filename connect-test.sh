#!/bin/bash

export JSLEE_HOME=$PWD
export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
#export REPORT=$REPORTS/connect-report.log
export CONNECT_ERRCOUNT=0

#rm -rf $LOG/*
#rm -rf $REPORTS/*
#mkdir -p $LOG
#mkdir -p $REPORTS

echo "================================================================================" >> $REPORT
echo "SLEE Connectivity Tests Report" >> $REPORT
echo "================================================================================" >> $REPORT

export SUCCESS=0

echo -e "\nColocated test"
./connect-test-colocated.sh
export SUCCESS=$?

echo "Wait 10 seconds.."
sleep 10

echo -e "\nSeparate test"
./connect-test-separate.sh
export SUCCESS=$?

echo -e "\nSLEE Connectivity Summary:  $CONNECT_ERRCOUNT error(s)\n"
echo -e "\nSLEE Connectivity Summary:  $CONNECT_ERRCOUNT error(s)\n" >> $REPORT
echo "================================================================================" >> $REPORT

if [ "$CONNECT_ERRCOUNT" != 0 ] && [ "$SUCCESS" == 1 ]
then
  export SUCCESS=0
fi

rm -f $LOG/temp-*-0.log
rm -f $LOG/temp-*-1.log
rm -f $LOG/temp-*-2.log

exit $SUCCESS
