#!/bin/bash

# Colocated Test

export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
echo $JBOSS_HOME

# Start JSLEE
$JBOSS_HOME/bin/run.sh > $LOG/connect-colocated-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

echo "Waiting 120 seconds"
sleep 120

# Deploy
echo -e "\nDeploy SLEE Connectivity Example\n"
cp $LOG/connect-colocated-jboss.log $LOG/connect-colocated-jboss-0.log

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy
echo "Waiting 10 seconds"
sleep 10

diff $LOG/connect-colocated-jboss-0.log $LOG/connect-colocated-jboss.log > $LOG/connect-colocated-deploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-colocated-deploy.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in deploy:"
  echo "Error in deploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-colocated-deploy.log
  grep -A 2 -B 2 " ERROR " $LOG/connect-colocated-deploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-colocated-deploy.log\n"
  echo -e "> ... see in file $LOG/connect-colocated-deploy.log\n" >> $REPORT
fi


# Colocated Test
cp $LOG/connect-colocated-jboss.log $LOG/connect-colocated-jboss-1.log

echo "Execute: twiddle.sh -s localhost:1099 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld"
sh $JBOSS_HOME/bin/twiddle.sh -s localhost:1099 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld
echo "Waiting 10 seconds"
sleep 10

diff $LOG/connect-colocated-jboss-1.log $LOG/connect-colocated-jboss.log > $LOG/connect-colocated.log

# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-colocated.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
export SUCCESS=0
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
    export SUCCESS=1
  else
    echo "SLEE Connectivity Example Colocated Test is FAILED"
    echo "SLEE Connectivity Example Colocated Test is FAILED" >> $REPORT
    echo -e "> ... see in file $LOG/connect-colocated.log\n" >> $REPORT
    export SUCCESS=0
  fi
fi

# Undeploy
echo -e "\nUndeploy SLEE Connectivity Example\n"
cp $LOG/connect-colocated-jboss.log $LOG/connect-colocated-jboss-2.log

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy
echo "Waiting 10 seconds"
sleep 10

diff $LOG/connect-colocated-jboss-2.log $LOG/connect-colocated-jboss.log > $LOG/connect-colocated-undeploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-colocated-undeploy.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in Undeploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-colocated-undeploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-colocated-undeploy.log\n" >> $REPORT
fi

echo -e "\nColocated result:  $CONNECT_ERRCOUNT error(s)\n"

pkill -TERM -P $JBOSS_PID
echo "Waiting 30 seconds"
sleep 30

exit $SUCCESS
