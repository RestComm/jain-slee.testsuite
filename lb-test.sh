#!/bin/bash

export JSLEE=$PWD
export LOG=$JSLEE/test-logs
export REPORTS=$JSLEE/test-reports
export REPORT=$REPORTS/loadbalancer-report.log

export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA
export JAVA_OPTS="-Xms1024m -Xmx1024m -XX:PermSize=128M -XX:MaxPermSize=256M -XX:+UseConcMarkSweepGC -XX:+CMSIncrementalMode"

export SIPP=$JSLEE/test-tools/sipp/sipp
export LBTEST=$JSLEE/test-tools/load-balancer

./lb-test-prepare.sh uas
./lb-test-uas-perf.sh
