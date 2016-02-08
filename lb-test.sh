#!/bin/bash

export JSLEE=$PWD
export LOG=$JSLEE/test-logs
export REPORTS=$JSLEE/test-reports
export REPORT=$REPORTS/loadbalancer-report.log

export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"

export SIPP=$JSLEE/test-tools/sipp/sipp

export LBVERSION=2.0.21
export LBTEST=$JSLEE/test-tools/load-balancer
export LBPATH=$JSLEE/extra/sip-balancer

echo -e "LB Report\n" > $REPORT

./lb-test-prepare.sh uas-lb
./lb-test-uas-perf.sh
export UAS_SUCCESS=$?

exit $UAS_SUCCESS
#echo "Waiting 30 seconds"
#sleep 30

#./lb-test-prepare.sh b2bua-lb
#./lb-test-b2b-func.sh
#export B2B_SUCCESS=$?

#export SUCCESS=0
#if [ "$UAS_SUCCESS" == 1 ] && [ "$B2B_SUCCESS" == 1 ]
#then
#  export SUCCESS=1
#fi

#exit $SUCCESS
