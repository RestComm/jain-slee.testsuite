#!/bin/bash

export JSLEE=$PWD
export LOG=$JSLEE/test-logs
export REPORTS=$JSLEE/test-reports
#export REPORT=$REPORTS/loadbalancer-report.log

cd $JSLEE_HOME/wildfly-*
export JBOSS_HOME=$PWD
cd -
export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"

export SIPP=$JSLEE/test-tools/sipp/sipp
$SIPP -v

killall sipp

export LBTEST=$JSLEE/test-tools/load-balancer
export LBPATH=$JSLEE/extra/sip-balancer

echo -e "\nLoadBalancer Tests Report\n" >> $REPORT

### UAS

export SERVER1=$JSLEE_RELEASE/server1
export SERVER2=$JSLEE_RELEASE/server2
export SERVER1_HOME=$SERVER1/wildfly-10.1.0.Final
export SERVER2_HOME=$SERVER2/wildfly-10.1.0.Final

./lb-test-prepare.sh uas-lb

./lb-test-uas-perf.sh
export UAS_PERF_SUCCESS=$?

./lb-test-uas-failover.sh
export UAS_FAILOVER_SUCCESS=$?

### B2BUA

./lb-test-prepare.sh b2bua-lb

./lb-test-b2b-func.sh
export B2B_FUNC_SUCCESS=$?

./lb-test-b2b-failover1.sh
export B2B_CONFIRMED_FAILOVER_SUCCESS=$?

./lb-test-b2b-failover2.sh
export B2B_EARLY_FAILOVER_SUCCESS=$?

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

rm -Rf $SERVER1
rm -Rf $SERVER2

echo "SUCCESS: $SUCCESS"
exit $SUCCESS
