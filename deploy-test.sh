#!/bin/bash

export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
export REPORT=$REPORTS/deploy-report.log
export DEPLOY_ERRCOUNT=0
export SUCCESS=0

function check
{
  echo "Check $1"
  pwd
  cd $1
  pwd
  
  cp $LOG/deploy-jboss.log $LOG/temp-"$1"-0.log
  echo "Deploy: $2"
  ERRCOUNT=0
  ant $2
  deployAnt=$?
  if [ $deployAnt -ne 0 ]
  then
    ERRCOUNT=1
  fi
  echo "Wait $3 seconds.."
  sleep $3
  diff $LOG/temp-"$1"-0.log $LOG/deploy-jboss.log > $LOG/temp-"$1".deploy.log
  
  # grep error
  TEST=$(grep -ic " error " $LOG/temp-$1.deploy.log)
  ERRCOUNT=$((ERRCOUNT+TEST))
  if [ "$ERRCOUNT" != 0 ]
  then
    PERSISTENCE_ERRCOUNT=$(grep -ic "Container is providing a null PersistenceUnitRootUrl" $LOG/temp-$1.deploy.log)
    ERRCOUNT=$((ERRCOUNT-PERSISTENCE_ERRCOUNT))
  fi
  DEPLOY_ERRCOUNT=$((DEPLOY_ERRCOUNT+ERRCOUNT))

  printf "        %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)"
  printf "        %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)" >> $REPORT
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $REPORT
    grep -i -A 4 -B 2 " error " $LOG/temp-$1.deploy.log >> $REPORT
    echo -e "> ... see in file $LOG/temp-$1.deploy.log\n" >> $REPORT
  fi
  
  cp $LOG/deploy-jboss.log $LOG/temp-"$1"-1.log
  echo "Undeploy: $4"
  ERRCOUNT=0
  ant $4
  undeployAnt=$?
  if [ $undeployAnt -ne 0 ]
  then
    ERRCOUNT=1
  fi
  echo "Wait $3 seconds.."
  sleep $5
  diff $LOG/temp-"$1"-1.log $LOG/deploy-jboss.log > $LOG/temp-"$1".undeploy.log
  
  # grep error
  TEST=$(grep -ic " error " $LOG/temp-$1.undeploy.log)
  ERRCOUNT=$((ERRCOUNT+TEST))
  DEPLOY_ERRCOUNT=$((DEPLOY_ERRCOUNT+ERRCOUNT))
  
  printf "        %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)"
  printf "        %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)" >> $REPORT
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $REPORT
    grep -i -A 4 -B 2 " error " $LOG/temp-$1.undeploy.log >> $REPORT
    echo -e "> ... see in file $LOG/temp-$1.undeploy.log\n" >> $REPORT
  fi
  
  cd ..
}

function startSlee 
{
	export START=1
	$JBOSS_HOME/bin/standalone.sh > $LOG/deploy-jboss.log 2>&1 &
	export JBOSS_PID="$!"
	echo "starting slee instance JBOSS_PID: $JBOSS_PID"

	TIME=0
	while :; do
	  sleep 15
	  TIME=$((TIME+10))
	  echo " .. $TIME seconds"
	  STARTED_IN=$(grep -c " started in " $LOG/deploy-jboss.log)
	  if [ "$STARTED_IN" == 1 ]; then break; fi

	  if [ $TIME -gt 60 ]; then
	    export START=0
	    break
	  fi

	# skipping license errors
	sleep 5

	done
}

function stopSlee 
{
	echo "stopping slee instance"
	pkill -TERM -P $JBOSS_PID
	echo "Wait 10 seconds.."
	sleep 10
}


cd $JSLEE_HOME/wildfly-*
export JBOSS_HOME=$PWD
cd -
export DIAMETER_STACK=$JSLEE_HOME/extra/telscale-diameter/TelScale-diameter-mux-wildfly-*
export SS7_STACK=$JSLEE_HOME/extra/telscale-ss7/TelScale-jss7-*/ss7-wildfly
echo $JBOSS_HOME

echo "================================================================================" >> $REPORT
echo "Deployment Test Report" >> $REPORT
echo "================================================================================" >> $REPORT


# Resources
startSlee

echo -e "\n     RAs:\n" >> $REPORT
cd $JSLEE_HOME/resources
check tftp-server deploy 7 undeploy 7
check jdbc deploy 7 undeploy 7
check xmpp deploy 7 undeploy 7
check mgcp deploy 7 undeploy 7
check mscontrol deploy 7 undeploy 7
check xcap-client deploy 7 undeploy 7
check sip11 deploy 7 undeploy 7

stopSlee

#HTTP
cd $JSLEE_HOME/extra/telscale-http
ant deploy

startSlee 

cd $JSLEE_HOME/resources
check http-servlet deploy 7 undeploy 7
check http-client deploy 7 undeploy 7
check http-client-nio deploy 7 undeploy 7

cd ../enablers
check rest-client deploy-all 7 undeploy-all 7

stopSlee

cd $JSLEE_HOME/extra/telscale-http
ant undeploy

# Diameter
echo -e "\n    Deploy jDiameter Stack Mux" >> $REPORT
cd $DIAMETER_STACK
ant deploy
cd -

startSlee
if [ "$START" -eq 0 ]; then
	  echo "There is a problem with starting JBoss!"
	  stopSlee
	  exit $SUCCESS
	fi

cd $JSLEE_HOME/resources

check diameter-base deploy 7 undeploy 7

ant -f diameter-base/build.xml deploy
echo "Wait 7 seconds.."
sleep 7

check diameter-cca deploy 7 undeploy 7

ant -f diameter-cca/build.xml deploy
echo "Wait 7 seconds.."
sleep 7

check diameter-gx deploy 7 undeploy 7
check diameter-rx deploy 7 undeploy 7

ant -f diameter-cca/build.xml undeploy
echo "Wait 7 seconds.."
sleep 7

check diameter-cx-dx deploy 7 undeploy 7
check diameter-gq deploy 7 undeploy 7
check diameter-rf deploy 7 undeploy 7
check diameter-ro deploy 7 undeploy 7
check diameter-s6a deploy 7 undeploy 7
check diameter-sh-client deploy 7 undeploy 7
check diameter-sh-server deploy 7 undeploy 7

cd $JSLEE_HOME/resources
ant -f diameter-base/build.xml undeploy
echo "Wait 7 seconds.."
sleep 7

echo -e "\n    Enablers:\n" >> $REPORT

cd $JSLEE_HOME/enablers
check hss-client deploy-all 10 undeploy-all 10

# Remove Diameter Mux

echo -e "\n    Undeploy jDiameter Stack Mux\n" >> $REPORT
cd $DIAMETER_STACK
ant undeploy
cd -

stopSlee

#
echo -e "\n    RAs:\n" >> $REPORT

# SS7

# Install jSS7 Stack
echo -e "    Deploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant deploy

startSlee
if [ "$START" -eq 0 ]; then
	  echo "There is a problem with starting JBoss!"
	  stopSlee
	  exit $SUCCESS
	fi

# deploy resources
cd $JSLEE_HOME/resources
check map deploy 7 undeploy 7
check cap deploy 7 undeploy 7
check tcap deploy 7 undeploy 7
check isup deploy 7 undeploy 7

# Uninstall jSS7 Stack

stopSlee

echo -e "\n    Undeploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant undeploy
echo "Wait 7 seconds.."
sleep 7

if [ "$START" -eq 0 ]; then
	  echo "There is a problem with starting JBoss!"
	  stopSlee
	  exit $SUCCESS
	fi

# Examples
echo -e "\n    Examples:\n" >> $REPORT

cd $JSLEE_HOME/examples/slee-connectivity
ant deploy-colocated

startSlee

cd $JSLEE_HOME/examples
check slee-connectivity deploy-remote-server-du 7 undeploy-remote-server-du 7

stopSlee

cd $JSLEE_HOME/examples/slee-connectivity
ant undeploy-colocated

startSlee

cd $JSLEE_HOME/examples
check mscontrol-demo deploy-all 15 undeploy-all 15
check mgcp-demo deploy-all 15 undeploy-all 15
check google-talk-bot deploy-all 15 undeploy-all 15
check sip-b2bua deploy-all 15 undeploy-all 15
check sip-jdbc-registrar deploy-all 15 undeploy-all 15
check sip-uas deploy-all 15 undeploy-all 15
check sip-wake-up deploy-all 15 undeploy-all 15
# sleep required for sip-wake-up
sleep 60

# Enablers
echo -e "\n    Enablers:\n" >> $REPORT

cd $JSLEE_HOME/enablers

check rest-client deploy-all 15 undeploy-all 15
check sip-publication-client deploy-all 15 undeploy-all 15
check sip-subscription-client deploy-all 15 undeploy-all 15
check xdm-client deploy-all 15 undeploy-all 15
check sip-publication-client deploy-all 15 undeploy-all 15
check sip-subscription-client deploy-all 15 undeploy-all 15

echo -e "\nDeploy Summary:  $DEPLOY_ERRCOUNT error(s)\n"
echo -e "\nDeploy Summary:  $DEPLOY_ERRCOUNT error(s)\n" >> $REPORT
echo "================================================================================" >> $REPORT
if [ "$DEPLOY_ERRCOUNT" == 0 ]
then
  export SUCCESS=1
fi

stopSlee

#rm -f $LOG/temp-*-0.log
#rm -f $LOG/temp-*-1.log

exit $SUCCESS
