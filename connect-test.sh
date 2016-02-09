#!/bin/bash

export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
#export REPORT=$REPORTS/connect-report.log
export CONNECT_ERRCOUNT=0

#rm -rf $LOG/*
#rm -rf $REPORTS/*
#mkdir -p $LOG
#mkdir -p $REPORTS

echo -e "\nSLEE Connectivity Tests Report\n" >> $REPORT

export SUCCESS=0

echo -e "\nColocated test"
./connect-test-colocated.sh
export SUCCESS=$?

echo "Waiting 10 seconds"
sleep 10

echo -e "\nSeparate test"
./connect-test-separate.sh
export SUCCESS=$?

echo -e "\SLEE Connectivity Summary: $CONNECT_ERRCOUNT error(s)\n"
echo -e "\SLEE Connectivity Summary: $CONNECT_ERRCOUNT error(s)\n" >> $REPORT
if [ "$CONNECT_ERRCOUNT" != 0 ] && [ "$SUCCESS" == 1 ]
then
  export SUCCESS=0
fi

#rm -f $LOG/temp-*-0.log
#rm -f $LOG/temp-*-1.log

exit $SUCCESS