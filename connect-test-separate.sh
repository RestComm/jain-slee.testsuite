#!/bin/bash

# Separate Test

cd $JSLEE_HOME/wildfly-*
export JBOSS_HOME=$PWD
cd -
echo $JBOSS_HOME

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy-remote-server

# start JSLEE wildfly instance
$JBOSS_HOME/bin/standalone.sh > $LOG/connect-separate-jboss.log 2>&1 &
SLEE_WILDFLY_PID="$!"
echo "Wildfly/JSLEE PID: $SLEE_WILDFLY_PID"

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  STARTED_IN=$(grep -c " started in " $LOG/connect-separate-jboss.log)
  if [ "$STARTED_IN" == 1 ]; then break; fi
done

# Deploy connectivity-du
echo -e "\nDeploy SLEE Connectivity Example\n"
cp $LOG/connect-separate-jboss.log $LOG/temp-connect-separate-jboss-0.log

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy-remote-server-du 
echo "Wait 7 seconds.."
sleep 7

cd $JSLEE_RELEASE
echo "downloading wildfly.."
wget -nc -q http://download.jboss.org/wildfly/10.1.0.Final/wildfly-10.1.0.Final.zip
unzip -q $JSLEE_RELEASE/wildfly-10.1.0.Final.zip -d $JSLEE_RELEASE/wildfly
export WILDFLY_FOLDER=$JSLEE_RELEASE/wildfly
export WILDFLY_HOME=$WILDFLY_FOLDER/wildfly-10.1.0.Final

mkdir -p $WILDFLY_FOLDER/examples
cp -R $JSLEE_HOME/examples/slee-connectivity $WILDFLY_FOLDER/examples

cd $WILDFLY_FOLDER/examples/slee-connectivity
ant deploy-remote-client

# start Client wildfly instance
WILDFLY_HOSTNAME=127.0.0.2
export JBOSS_HOME_OLD=$JBOSS_HOME
export JBOSS_HOME=$WILDFLY_HOME
$WILDFLY_HOME/bin/standalone.sh -b $WILDFLY_HOSTNAME -bmanagement=$WILDFLY_HOSTNAME > $LOG/connect-separate-jboss-2.log 2>&1 &
CLIENT_WILDFLY_PID="$!"
echo "Wildfly/Client PID: $CLIENT_WILDFLY_PID"

TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo "$TIME seconds"
  STARTED_IN=$(grep -c " started in " $LOG/connect-separate-jboss-2.log)
  if [ "$STARTED_IN" == 1 ]; then break; fi
done

#Create jmx user
TWIDDLE_USER=test
TWIDDLE_PASSWORD=test
sh $WILDFLY_HOME/bin/add-user.sh $TWIDDLE_USER $TWIDDLE_PASSWORD
sleep 1

cp $LOG/connect-separate-jboss-2.log $LOG/temp-connect-separate-jboss-10.log

export JBOSS_HOME=$JBOSS_HOME_OLD

cd $WILDFLY_FOLDER/examples/slee-connectivity
ant deploy-remote-client-du
echo "Wait 7 seconds.."
sleep 7

diff $LOG/temp-connect-separate-jboss-10.log $LOG/connect-separate-jboss-2.log > $LOG/temp-connect-separate.deploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect-separate.deploy.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in deploy Separate Test:"
  echo "    Error in deploy Separate Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate-deploy.log
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate-deploy.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect-separate.deploy.log\n"
  echo -e "> ... see in file $LOG/temp-connect-separate.deploy.log\n" >> $REPORT
fi

# Separate Test
cp $LOG/connect-separate-jboss.log $LOG/temp-connect-separate-jboss-11.log
cp $LOG/connect-separate-jboss-2.log $LOG/temp-connect-separate-jboss-21.log

mkdir $WILDFLY_FOLDER/tools
cp -R $JSLEE_HOME/tools/twiddle $WILDFLY_FOLDER/tools
echo "Execute: twiddle/twiddle.sh --user=test --password=test -s service:jmx:http-remoting-jmx://127.0.0.2:9990 invoke org.mobicents.slee:type=SleeConnectionTest fireEvent helloworld"
sh $WILDFLY_FOLDER/tools/twiddle/twiddle.sh --user=$TWIDDLE_USER --password=$TWIDDLE_PASSWORD -s service:jmx:http-remoting-jmx://$WILDFLY_HOSTNAME:9990 invoke org.mobicents.slee:type=SleeConnectionTest fireEvent helloworld
echo "Wait 5 seconds.."
sleep 5

diff $LOG/temp-connect-separate-jboss-11.log $LOG/connect-separate-jboss.log > $LOG/temp-connect.separate.log
diff $LOG/temp-connect-separate-jboss-21.log $LOG/connect-separate-jboss-2.log > $LOG/temp-connect.separate-2.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect.separate.log)
ERRCOUNT_CLIENT=$(grep -c " ERROR " $LOG/temp-connect.separate-2.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT_CLIENT))
export SUCCESS=0
if [ "$ERRCOUNT" != 0 ]
then
  echo "    Error in executing Separate Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect.separate.log >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect.separate-2.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect.separate.log and $LOG/temp-connect.separate-2.log\n" >> $REPORT
else
  ISRESULT=$(grep -c "helloworld" $LOG/temp-connect.separate.log)
  if [ "$ISRESULT" != 0 ]
  then
    echo -e "SLEE Connectivity Separate Test is SUCCESSFUL\n"
    echo -e "    SLEE Connectivity Separate Test is SUCCESSFULLY\n" >> $REPORT
    export SUCCESS=1
  else
    echo -e "SLEE Connectivity Separate Test FAILED\n"
    echo -e "    SLEE Connectivity Separate Test FAILED\n" >> $REPORT
    echo -e "> ... see in file $LOG/temp-connect.separate.log\n" >> $REPORT
    export SUCCESS=0
  fi
fi

# Undeploy
echo -e "\nUndeploy SLEE Connectivity Example\n"
cp $LOG/connect-separate-jboss.log $LOG/temp-connect-separate-jboss-12.log
cp $LOG/connect-separate-jboss-2.log $LOG/temp-connect-separate-jboss-22.log
cd $WILDFLY_FOLDER/examples/slee-connectivity
ant undeploy-remote-client-du
echo "Wait 5 seconds.."
sleep 5

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy-remote-server-du
echo "Wait 5 seconds.."
sleep 5

diff $LOG/temp-connect-separate-jboss-12.log $LOG/connect-separate-jboss.log > $LOG/temp-connect-separate.undeploy.log
diff $LOG/temp-connect-separate-jboss-22.log $LOG/connect-separate-jboss-2.log > $LOG/temp-connect-separate.undeploy-2.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/temp-connect-separate.undeploy.log)
ERRCOUNT_CLIENT=$(grep -c " ERROR " $LOG/temp-connect-separate.undeploy-2.log)
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT))
CONNECT_ERRCOUNT=$((CONNECT_ERRCOUNT+ERRCOUNT_CLIENT))
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in undeploy Colocated Test:"
  echo "    Error in undeploy Colocated Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate.undeploy.log
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate.undeploy.log >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate.undeploy-2.log
  grep -A 2 -B 2 " ERROR " $LOG/temp-connect-separate.undeploy-2.log >> $REPORT
  echo -e "> ... see in file $LOG/temp-connect-separate.undeploy.log and $LOG/temp-connect-separate.undeploy-2.log\n"
  echo -e "> ... see in file $LOG/temp-connect-separate.undeploy.log and $LOG/temp-connect-separate.undeploy-2.log\n" >> $REPORT
fi

echo -e "\nColocated Summary:  $CONNECT_ERRCOUNT error(s)\n"

pkill -TERM -P $CLIENT_WILDFLY_PID
echo "Wait 5 seconds.."
sleep 5

cd $WILDFLY_FOLDER/examples/slee-connectivity
ant undeploy-remote-client

pkill -TERM -P $SLEE_WILDFLY_PID
echo "Wait 5 seconds.."
sleep 5

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy-remote-server

exit $SUCCESS
