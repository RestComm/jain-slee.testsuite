#!/bin/bash

#export HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
export REPORT=$REPORTS/connect-report.log

#export UPHOME="$(dirname "$HOME")"
echo $JSLEE_RELEASE
rm $JSLEE_RELEASE/jboss*.*
wget -P$JSLEE_RELEASE -nc -q -o /dev/null http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA-jdk6.zip

export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
echo $JBOSS_HOME

rm -rf $LOG/*
rm -rf $REPORTS/*
mkdir -p $LOG
mkdir -p $REPORTS

# Start JSLEE
$JBOSS_HOME/bin/run.sh > $LOG/connect-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

sleep 20

echo -e "SLEE Connectivity Report\n" >> $REPORT

# Colocated Test

# Deploy
echo -e "\nDeploy SLEE Connectivity Example\n"
cp $LOG/connect-jboss.log $LOG/connect-jboss-0.log

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy
sleep 5

diff $LOG/connect-jboss-0.log $LOG/connect-jboss.log > $LOG/connect-deploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-deploy.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in deploy:"
  echo "Error in deploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-deploy.log
  grep -A 2 -B 2 " ERROR " $LOG/connect-deploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-deploy.log\n"
  echo -e "> ... see in file $LOG/connect-deploy.log\n" >> $REPORT
fi


# Colocated Test
cp $LOG/connect-jboss.log $LOG/connect-jboss-1.log

sh $JBOSS_HOME/bin/twiddle.sh invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld
sleep 5

diff $LOG/connect-jboss-1.log $LOG/connect-jboss.log > $LOG/connect-colocated.log

# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-colocated.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in Colocated Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-colocated.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-colocated.log\n" >> $REPORT
else
  # grep result - helloworld
  ISRESULT=$(grep -c "helloworld" $LOG/connect-colocated.log)
  if [ "$ISRESULT" != 0 ]
  then
    echo "SLEE Connectivity Example Colocated Test is SUCCESS"
    echo "SLEE Connectivity Example Colocated Test is SUCCESS" >> $REPORT
  else
    echo "SLEE Connectivity Example Colocated Test is FAILED"
    echo "SLEE Connectivity Example Colocated Test is FAILED" >> $REPORT
    echo -e "> ... see in file $LOG/connect-colocated.log\n" >> $REPORT
  fi
fi

# Undeploy
echo -e "\nUndeploy SLEE Connectivity Example\n"
cp $LOG/connect-jboss.log $LOG/connect-jboss-2.log

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy
sleep 5

diff $LOG/connect-jboss-2.log $LOG/connect-jboss.log > $LOG/connect-undeploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-undeploy.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in Undeploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-undeploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-undeploy.log\n" >> $REPORT
fi

pkill -TERM -P $JBOSS_PID
sleep 10

#rm -f $LOG/out-*-0.log
#rm -f $LOG/out-*-1.log

# JBoss/JSLEE on default
$JBOSS_HOME/bin/run.sh > $LOG/connect-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

sleep 20

#

# JBoss on default with port-01

#


pkill -TERM -P $JBOSS_PID
