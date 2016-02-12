#!/bin/bash

export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
#export REPORT=$REPORTS/deploy-report.log
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
  ant $2
  echo "Wait $3 seconds.."
  sleep $3
  diff $LOG/temp-"$1"-0.log $LOG/deploy-jboss.log > $LOG/temp-"$1".deploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $LOG/temp-$1.deploy.log)
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
  ant $4
  echo "Wait $3 seconds.."
  sleep $5
  diff $LOG/temp-"$1"-1.log $LOG/deploy-jboss.log > $LOG/temp-"$1".undeploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $LOG/temp-$1.undeploy.log)
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

# Start JSLEE
export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
export DIAMETER_STACK=$JSLEE_HOME/extra/restcomm-diameter
export SS7_STACK=$JSLEE_HOME/extra/restcomm-ss7/restcomm-jss7-*/ss7
echo $JBOSS_HOME

export START=1
$JBOSS_HOME/bin/run.sh > $LOG/deploy-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

#sleep 120
TIME=0
while :; do
  sleep 10
  TIME=$((TIME+10))
  echo " .. $TIME seconds"
  STARTED_IN=$(grep -c " Started in " $LOG/deploy-jboss.log)
  if [ "$STARTED_IN" == 1 ]; then break; fi

  if [ $TIME -gt 300 ]; then
    export START=0
    break
  fi
done

if [ "$START" -eq 0 ]; then
  echo "There is a problem with starting JBoss!"
  echo "Wait 10 seconds.."
  
  pkill -TERM -P $JBOSS_PID
  sleep 10
  exit $SUCCESS
fi

echo "================================================================================" >> $REPORT
echo "Deployment Test Report\n" >> $REPORT
echo "================================================================================" >> $REPORT

# Diameter
# Copy Diameter Mux sar to server/default/deploy
echo -e "\n    Deploy jDiameter Stack Mux" >> $REPORT
cp -r $DIAMETER_STACK/restcomm-diameter-mux-*.sar $JBOSS_HOME/server/default/deploy
echo "Wait 10 seconds.."
sleep 10

# Resources
echo -e "\n     RAs:\n" >> $REPORT
cd $JSLEE_HOME/resources

check diameter-base deploy 10 undeploy 10

ant -f diameter-base/build.xml deploy
echo "Wait 10 seconds.."
sleep 10
check diameter-cca deploy 10 undeploy 10

ant -f diameter-cca/build.xml deploy
echo "Wait 10 seconds.."
sleep 10

check diameter-gx deploy 10 undeploy 10
check diameter-rx deploy 10 undeploy 10

ant -f diameter-cca/build.xml undeploy
echo "Wait 10 seconds.."
sleep 10

check diameter-cx-dx deploy 10 undeploy 10
check diameter-gq deploy 10 undeploy 10
check diameter-rf deploy 10 undeploy 10
check diameter-ro deploy 10 undeploy 10
check diameter-s6a deploy 10 undeploy 10
check diameter-sh-client deploy 10 undeploy 10
check diameter-sh-server deploy 10 undeploy 10

echo -e "\n    Enablers:\n" >> $REPORT

cd $JSLEE_HOME/enablers
check hss-client deploy-all 10 undeploy-all 10

cd $JSLEE_HOME/resources
ant -f diameter-base/build.xml undeploy
echo "Wait 10 seconds.."
sleep 10

# Remove Diameter Mux sar from server/default/deploy
echo -e "\n    Undeploy jDiameter Stack Mux\n" >> $REPORT
rm -rf $JBOSS_HOME/server/default/deploy/restcomm-diameter-mux-*.sar
echo "Wait 30 seconds.."
sleep 30

#
echo -e "\n    RAs:\n" >> $REPORT

# SS7

# Install jSS7 Stack
echo -e "    Deploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant deploy
echo "Wait 15 seconds.."
sleep 15

cd $JSLEE_HOME/resources
SS7_RA="map cap tcap isup"
for dir in $SS7_RA
do
  if [ $dir != "isup" ]
  then
    echo $dir
    check $dir deploy 15 undeploy 15
  fi
done

# Uninstall jSS7 Stack
echo -e "\n    Undeploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant undeploy
echo "Wait 15 seconds.."
sleep 15

# Other
# Start SMPP Server for SMPP RA
cd $JSLEE_HOME/test-tools/smpp-server
java -cp smpp.server-0.0.1-SNAPSHOT.jar:lib/* org.mobicents.tools.smpp.server.ServerSMPP 2775 > $LOG/temp-smpp.server.log 2>&1 &
SMPPSERVER_PID=$!
echo "SMPP Server: $SMPPSERVER_PID"

cd $JSLEE_HOME/resources
for dir in */
do
  dir=${dir%*/}
  if [ "$dir" == "${dir%diameter*}" ] && [ "${SS7_RA/$dir}" = "$SS7_RA" ]
  then
    echo "${dir} is not in Diameter and SS7"
    check $dir deploy 15 undeploy 15
  fi
done

# Stop SMPP Server
kill -9 $SMPPSERVER_PID

# Examples
echo -e "\n    Examples:\n" >> $REPORT

cd $JSLEE_HOME/examples
for dir in */
do
  dir=${dir%*/}
  echo ${dir##*/}
  case $dir in
    call-controller2)
      check $dir deploy-all 15 undeploy-all 30
      ;;
    slee-connectivity)
      check $dir deploy 15 undeploy 15
      ;;
    google-talk-bot)
      ;;
    *)
      check $dir deploy-all 15 undeploy-all 15
      ;;
  esac
done

# Enablers
echo -e "\n    Enablers:\n" >> $REPORT

cd $JSLEE_HOME/enablers
for dir in */
do
  dir=${dir%*/}
  if [ $dir != "hss-client" ]
  then
    echo $dir
    check $dir deploy-all 15 undeploy-all 15
  fi
done

echo -e "\nDeploy Summary:  $DEPLOY_ERRCOUNT error(s)\n"
echo -e "\nDeploy Summary:  $DEPLOY_ERRCOUNT error(s)\n" >> $REPORT
echo "================================================================================" >> $REPORTS
if [ "$DEPLOY_ERRCOUNT" == 0 ]
then
  export SUCCESS=1
fi

# Tools


pkill -TERM -P $JBOSS_PID
echo "Wait 10 seconds.."
sleep 10

rm -f $LOG/temp-*-0.log
rm -f $LOG/temp-*-1.log

exit $SUCCESS
