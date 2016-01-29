#!/bin/bash

#export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
export REPORT=$REPORTS/connect-report.log

#export UPHOME="$(dirname "$HOME")"
#echo $JSLEE_RELEASE
#wget -nc -q -o /dev/null -P$JSLEE_RELEASE http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA-jdk6.zip

rm -rf $LOG/*
rm -rf $REPORTS/*
mkdir -p $LOG
mkdir -p $REPORTS

echo -e "SLEE Connectivity Report\n" >> $REPORT

echo -e "\nColocated test"
./connect-test-colocated.sh

sleep 10
echo -e "\nSeparate test"
./connect-test-separate.sh

#rm -f $LOG/out-*-0.log
#rm -f $LOG/out-*-1.log

