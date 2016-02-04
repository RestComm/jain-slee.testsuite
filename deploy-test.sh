#!/bin/bash

export JSLEE_HOME=$PWD
export LOG=$JSLEE_HOME/test-logs
export REPORTS=$JSLEE_HOME/test-reports
export REPORT=$REPORTS/deploy-report.log
export DEPLOY_ERRCOUNT=0

function check
{
  echo "Check $1"
  pwd
  cd $1
  pwd
  
  cp $LOG/deploy-jboss.log $LOG/out-"$1"-0.log
  echo "Deploy: $2"
  ant $2
  sleep $3
  diff $LOG/out-"$1"-0.log $LOG/deploy-jboss.log > $LOG/out-"$1".deploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $LOG/out-$1.deploy.log)
  if [ "$ERRCOUNT" != 0 ]
  then
    PERSISTENCE_ERRCOUNT=$(grep -ic "Container is providing a null PersistenceUnitRootUrl" $LOG/out-$1.deploy.log)
    ERRCOUNT=$((ERRCOUNT-PERSISTENCE_ERRCOUNT))
  fi
  DEPLOY_ERRCOUNT=$((DEPLOY_ERRCOUNT+ERRCOUNT))

  printf "    %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)"
  printf "    %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)" >> $REPORT
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $REPORT
    grep -i -A 4 -B 2 " error " $LOG/out-$1.deploy.log >> $REPORT
    echo -e "> ... see in file $LOG/out-$1.deploy.log\n" >> $REPORT
  fi
  
  cp $LOG/deploy-jboss.log $LOG/out-"$1"-1.log
  echo "Undeploy: $4"
  ant $4
  sleep $5
  diff $LOG/out-"$1"-1.log $LOG/deploy-jboss.log > $LOG/out-"$1".undeploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $LOG/out-$1.undeploy.log)
  DEPLOY_ERRCOUNT=$((DEPLOY_ERRCOUNT+ERRCOUNT))
  
  printf "    %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)"
  printf "    %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)" >> $REPORT
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $REPORT
    grep -i -A 4 -B 2 " error " $LOG/out-$1.undeploy.log >> $REPORT
    echo -e "> ... see in file $LOG/out-$1.undeploy.log\n" >> $REPORT
  fi
  
  cd ..
}

# Start JSLEE
export JBOSS_HOME=$JSLEE_HOME/jboss-5.1.0.GA
export DIAMETER_STACK=$JSLEE_HOME/extra/restcomm-diameter
export SS7_STACK=$JSLEE_HOME/extra/restcomm-ss7/mobicents-jss7-*/ss7
echo $JBOSS_HOME

#rm -rf $LOG/*
#rm -rf $REPORTS/*
#mkdir -p $LOG
#mkdir -p $REPORTS

$JBOSS_HOME/bin/run.sh > $LOG/deploy-jboss.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

sleep 60

echo -e "Deploy/Undeploy Report\n" >> $REPORT

# Diameter
# Copy Diameter Mux sar to server/default/deploy
echo -e "Deploy jDiameter Stack Mux" >> $REPORT
cp -r $DIAMETER_STACK/mobicents-diameter-mux-*.sar $JBOSS_HOME/server/default/deploy
sleep 15

# Resources
echo -e "\nRAs:\n" >> $REPORT
cd $JSLEE_HOME/resources

#for dir in diameter*/
#do
#  dir=${dir%*/}
#  echo ${dir##*/}
#done

check diameter-base deploy 15 undeploy 15

ant -f diameter-base/build.xml deploy
sleep 15
check diameter-cca deploy 15 undeploy 15

ant -f diameter-cca/build.xml deploy
sleep 15

check diameter-gx deploy 15 undeploy 15
check diameter-rx deploy 15 undeploy 15

ant -f diameter-cca/build.xml undeploy
sleep 15

check diameter-cx-dx deploy 15 undeploy 15
check diameter-gq deploy 15 undeploy 15
check diameter-rf deploy 15 undeploy 15
check diameter-ro deploy 15 undeploy 15
check diameter-s6a deploy 15 undeploy 15
check diameter-sh-client deploy 15 undeploy 15
check diameter-sh-server deploy 15 undeploy 15

echo -e "\nEnablers:\n" >> $REPORT

cd $JSLEE_HOME/enablers
check hss-client deploy-all 15 undeploy-all 15

cd $JSLEE_HOME/resources
ant -f diameter-base/build.xml undeploy
sleep 15

# Remove Diameter Mux sar from server/default/deploy
echo -e "\nUndeploy jDiameter Stack Mux\n" >> $REPORT
rm -rf $JBOSS_HOME/server/default/deploy/mobicents-diameter-mux-*.sar
sleep 30

#
echo -e "\nRAs:\n" >> $REPORT

# SS7

# Install jSS7 Stack
echo -e "Deploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant deploy
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
echo -e "\nUndeploy jSS7 Stack\n" >> $REPORT
cd $SS7_STACK
ant undeploy
sleep 15

# Other
# Start SMPP Server for SMPP RA
cd $JSLEE_HOME/test-tools/smpp-server
java -cp smpp.server-0.0.1-SNAPSHOT.jar:lib/* org.mobicents.tools.smpp.server.ServerSMPP 2775 > $LOG/smpp.server.log 2>&1 &
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
echo -e "\nExamples:\n" >> $REPORT

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
echo -e "\nEnablers:\n" >> $REPORT

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

echo -e "\nCommon result:  $DEPLOY_ERRCOUNT error(s)\n" >> $REPORT
if [ "$DEPLOY_ERRCOUNT" == 0 ]
then
  export DEPLOY_SUCCESS=true
fi

# Tools

rm -f $LOG/out-*-0.log
rm -f $LOG/out-*-1.log

pkill -TERM -P $JBOSS_PID
