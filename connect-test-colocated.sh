#!/bin/bash

# Colocated Test

export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
echo $JBOSS_HOME

# Start JSLEE
$JBOSS_HOME/bin/run.sh > $LOG/connect-colocated-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

#sleep 120
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  STARTED_IN=$(grep -c " Started in " $LOG/connect-colocated-jboss.log)
  if [ "$STARTED_IN" == 1 ]; then break; fi
done

# Deploy
echo -e "\nDeploy SLEE Connectivity Example\n"
cp $LOG/connect-colocated-jboss.log $LOG/temp-connect-colocated-jboss-0.log

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy
echo "Wait 10 seconds.."
sleep 10

diff $LOG/temp-connect-colocated-jboss-0.log $LOG/connect-colocated-jboss.log > $LOG/temp-connect-colocated.deploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect-colocated.deploy.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in deploy Colocated Test:"
  echo "    Error in deploy Colocated Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-colocated-deploy.log
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-colocated-deploy.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect-colocated.deploy.log\n"
  echo -e "> ... see in file $LOG/temp-connect-colocated.deploy.log\n" >> $REPORT
fi


# Colocated Test
cp $LOG/connect-colocated-jboss.log $LOG/temp-connect-colocated-jboss-1.log

echo "Execute: twiddle.sh -s localhost:1099 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld"
sh $JBOSS_HOME/bin/twiddle.sh -s localhost:1099 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld
echo "Wait 10 seconds.."
sleep 10

diff $LOG/temp-connect-colocated-jboss-1.log $LOG/connect-colocated-jboss.log > $LOG/temp-connect.colocated.log

# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect.colocated.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
export SUCCESS=0
if [ "$ERRCOUNT" != 0 ]
then
  echo "    Error in executing Colocated Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect.colocated.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect.colocated.log\n" >> $REPORT
else
  # grep result - helloworld
  ISRESULT=$(grep -c "helloworld" $LOG/temp-connect.colocated.log)
  if [ "$ISRESULT" != 0 ]
  then
    echo -e "SLEE Connectivity Colocated Test is SUCCESSFUL\n"
    echo -e "    SLEE Connectivity Colocated Test is SUCCESSFULLY\n" >> $REPORT
    export SUCCESS=1
  else
    echo -e "SLEE Connectivity Colocated Test FAILED\n"
    echo -e "    SLEE Connectivity Colocated Test FAILED\n" >> $REPORT
    echo -e "> ... see in file $LOG/temp-connect.colocated.log\n" >> $REPORT
    export SUCCESS=0
  fi
fi

# Undeploy
echo -e "\nUndeploy SLEE Connectivity Example\n"
cp $LOG/connect-colocated-jboss.log $LOG/temp-connect-colocated-jboss-2.log

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy
echo "Wait 10 seconds.."
sleep 10

diff $LOG/temp-connect-colocated-jboss-2.log $LOG/connect-colocated-jboss.log > $LOG/temp-connect-colocated.undeploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect-colocated.undeploy.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in undeploy Colocated Test:"
  echo "    Error in undeploy Colocated Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-colocated.undeploy.log
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-colocated.undeploy.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect-colocated.undeploy.log\n"
  echo -e "> ... see in file $LOG/temp-connect-colocated.undeploy.log\n" >> $REPORT
fi

echo -e "\nColocated Summary:  $CONNECT_ERRCOUNT error(s)\n"

pkill -TERM -P $JBOSS_PID
echo "Wait 10 seconds.."
sleep 10

exit $SUCCESS