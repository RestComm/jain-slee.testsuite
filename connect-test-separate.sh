#!/bin/bash

# Separate Test

wget -nc -q -o /dev/null -P$JSLEE_RELEASE http://freefr.dl.sourceforge.net/project/jboss/JBoss/JBoss-5.1.0.GA/jboss-5.1.0.GA-jdk6.zip
unzip -q $JSLEE_RELEASE/jboss-5.1.0.GA-jdk6.zip -d $JSLEE_RELEASE

export JBOSSJSLEE_HOME=$JSLEE_HOME/jboss-5.1.0.GA
echo "JBoss/JSLEE: $JBOSSJSLEE_HOME"
export JBOSSAS_HOME=$JSLEE_RELEASE/jboss-5.1.0.GA
echo "JBoss AS: $JBOSSAS_HOME"

# JBoss/JSLEE on default
export JBOSS_HOME=$JBOSSJSLEE_HOME
$JBOSS_HOME/bin/run.sh > $LOG/connect-separate-jboss.log 2>&1 &
JBOSSJSLEE_PID="$!"
echo "JBoss/JSLEE PID: $JBOSSJSLEE_PID"

sleep 10

# JBoss on default with ports-01
export JBOSS_HOME=$JBOSSAS_HOME
$JBOSS_HOME/bin/run.sh -Djboss.service.binding.set=ports-01 -Djboss.messaging.ServerPeerID=0 -Dsession.serialization.jboss=false > $LOG/connect-separate-as-jboss.log 2>&1 &
JBOSSAS_PID="$!"
echo "JBoss AS PID: $JBOSSAS_PID"

sleep 60

# Deploy to JBoss/JSLEE
echo -e "\nDeploy SLEE Connectivity Example\n"
cp $LOG/connect-separate-jboss.log $LOG/connect-separate-jboss-0.log
cp $LOG/connect-separate-as-jboss.log $LOG/connect-separate-as-jboss-0.log

#cd $JSLEE_HOME/examples/slee-connectivity
#ant deploy
cp $JSLEE_HOME/examples/slee-connectivity/mobicents-slee-connectivity-example-slee-DU-*.jar $JBOSSJSLEE_HOME/server/default/deploy
sleep 10

# Deploy to JBoss AS
cp -r $JSLEE_HOME/tools/remote-slee-connection/mobicents-slee-remote-connection.rar $JBOSSAS_HOME/server/default/deploy
sleep 10
cp -r $JSLEE_HOME/examples/slee-connectivity/mobicents-slee-connectivity-example-javaee-beans $JBOSSAS_HOME/server/default/deploy
sleep 10

diff $LOG/connect-separate-jboss-0.log $LOG/connect-separate-jboss.log > $LOG/connect-separate-deploy.log
diff $LOG/connect-separate-as-jboss-0.log $LOG/connect-separate-jboss.log >> $LOG/connect-separate-deploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-separate-deploy.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in deploy:"
  echo "Error in deploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-separate-deploy.log
  grep -A 2 -B 2 " ERROR " $LOG/connect-separate-deploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-separate-deploy.log\n"
  echo -e "> ... see in file $LOG/connect-separate-deploy.log\n" >> $REPORT
fi

sleep 10

# Separate Test
cp $LOG/connect-separate-jboss.log $LOG/connect-separate-jboss-1.log

echo "Execute: twiddle.sh -s localhost:1199 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld"
sh $JBOSSAS_HOME/bin/twiddle.sh -s localhost:1199 invoke org.mobicents.slee:name=SleeConnectivityExample fireEvent helloworld
sleep 20

diff $LOG/connect-separate-jboss-1.log $LOG/connect-separate-jboss.log > $LOG/connect-separate.log

# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-separate.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in Separate Test:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-separate.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-separate.log\n" >> $REPORT
else
  # grep result - helloworld
  ISRESULT=$(grep -c "helloworld" $LOG/connect-separate.log)
  if [ "$ISRESULT" != 0 ]
  then
    echo "SLEE Connectivity Example Separate Test is SUCCESS"
    echo "SLEE Connectivity Example Separate Test is SUCCESS" >> $REPORT
  else
    echo "SLEE Connectivity Example Separate Test is FAILED"
    echo "SLEE Connectivity Example Separate Test is FAILED" >> $REPORT
    echo -e "> ... see in file $LOG/connect-separate.log\n" >> $REPORT
  fi
fi

sleep 20

# Undeploy from JBoss AS
echo -e "\nUndeploy SLEE Connectivity Example\n"
cp $LOG/connect-separate-jboss.log $LOG/connect-separate-jboss-2.log
cp $LOG/connect-separate-as-jboss.log $LOG/connect-separate-as-jboss-2.log

rm -r $JBOSSAS_HOME/server/default/deploy/mobicents-slee-connectivity-example-javaee-beans
sleep 10
rm -r $JBOSSAS_HOME/server/default/deploy/mobicents-slee-remote-connection.rar
sleep 10

# Undeploy from JBoss/JSLEE
rm $JBOSSJSLEE_HOME/server/default/deploy/mobicents-slee-connectivity-example-slee-DU-*.jar
sleep 20

diff $LOG/connect-separate-jboss-2.log $LOG/connect-separate-jboss.log > $LOG/connect-separate-undeploy.log
diff $LOG/connect-separate-as-jboss-2.log $LOG/connect-separate-as-jboss.log >> $LOG/connect-separate-undeploy.log
# grep error
ERRCOUNT=$(grep -c " ERROR " $LOG/connect-separate-undeploy.log)
if [ "$ERRCOUNT" != 0 ]
then
  echo "Error in Undeploy:" >> $REPORT
  grep -A 2 -B 2 " ERROR " $LOG/connect-separate-undeploy.log >> $REPORT
  echo -e "> ... see in file $LOG/connect-separate-undeploy.log\n" >> $REPORT
fi

pkill -TERM -P $JBOSSJSLEE_PID
pkill -TERM -P $JBOSSAS_PID
sleep 60

rm -f $JSLEE_RELEASE/jboss-5.1.0.GA-jdk6.zip
rm -rf $JSLEE_RELEASE/jboss-5.1.0.GA
sleep 20
