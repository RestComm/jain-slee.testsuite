#!/bin/bash

export JSLEE=$PWD
export LOG=$JSLEE/test-logs
export REPORTS=$JSLEE/test-reports

#export REPORT=$REPORTS/loadbalancer-report.log

export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"

export SIPP=$JSLEE/test-tools/sipp/sipp

#export LBVERSION=2.0.24
#export LBVERSION=2.0.30
echo "LBVERSION: $LBVERSION"

export LBTEST=$JSLEE/test-tools/load-balancer
export LBPATH=$JSLEE/extra/sip-balancer

cd $JSLEE/..
CURR=$PWD
export LB_HOME1=$CURR/lb1
export LB_HOME2=$CURR/lb2
cd $JSLEE

echo "LB_HOME1: $LB_HOME1"
echo "LB_HOME2: $LB_HOME2"
export LB_JBOSS1=$LB_HOME1/jboss-5.1.0.GA
export LB_JBOSS2=$LB_HOME2/jboss-5.1.0.GA

echo -e "\nLoadBalancer Tests Report\n" >> $REPORT

### UAS

./lb-test-prepare.sh uas-lb

./lb-test-uas-perf.sh
export UAS_PERF_SUCCESS=$?
#exit $UAS_PERF_SUCCESS

./lb-test-uas-failover.sh
export UAS_FAILOVER_SUCCESS=$?
#exit $UAS_FAILOVER_SUCCESS

### B2BUA

./lb-test-prepare.sh b2bua-lb

./lb-test-b2b-func.sh
export B2B_FUNC_SUCCESS=$?
#export B2B_FUNC_SUCCESS=1
#exit $B2B_FUNC_SUCCESS

./lb-test-b2b-failover1.sh
export B2B_CONFIRMED_FAILOVER_SUCCESS=$?
#exit $B2B_CONFIRMED_FAILOVER_SUCCESS

./lb-test-b2b-failover2.sh
export B2B_EARLY_FAILOVER_SUCCESS=$?
#exit $B2B_EARLY_FAILOVER_SUCCESS

export SUCCESS=0
if [ "$UAS_PERF_SUCCESS" == 1 ] && [ "$B2B_FUNC_SUCCESS" == 1 ] && [ "$UAS_FAILOVER_SUCCESS" == 1 ] && [ "$B2B_CONFIRMED_FAILOVER_SUCCESS" == 1 ] && [ "$B2B_EARLY_FAILOVER_SUCCESS" == 1 ]
then
  export SUCCESS=1
  echo -e "\nLoadBalancer Summary: Tests are SUCCESSFUL\n"
  echo -e "\nLoadBalancer Summary: Tests are SUCCESSFUL\n" >> $REPORT
else
  echo -e "\nLoadBalancer Summary: Tests FAILED\n"
  echo -e "\nLoadBalancer Summary: Tests FAILED\n" >> $REPORT
fi

echo "SUCCESS: $SUCCESS"
exit $SUCCESS
