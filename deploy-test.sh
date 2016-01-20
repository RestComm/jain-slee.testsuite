#!/bin/bash

export HOME=$PWD

function check
{
  echo "Check $1"
  pwd
  cd $1
  pwd
  
  cp $6/out.0.log $6/out."$1".0.log
  echo "Deploy: $2"
  ant $2
  sleep $3
  diff $6/out."$1".0.log $6/out.0.log > $6/out."$1".deploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $6/out.$1.deploy.log)
  if [ "$ERRCOUNT" != 0 ]
  then
    PERSISTENCE_ERRCOUNT=$(grep -ic "Container is providing a null PersistenceUnitRootUrl" $6/out.$1.deploy.log)
    ERRCOUNT=$((ERRCOUNT-PERSISTENCE_ERRCOUNT))
  fi

  printf "    %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)"
  printf "    %-30s | %-10s | %-20s\n" $1 "Deploy" "$ERRCOUNT error(s)" >> $6/report.log
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $6/report.log
    grep -i -A 4 -B 2 " error " $6/out.$1.deploy.log >> $6/report.log
    echo -e "> ... see in file $6/out.$1.deploy.log\n" >> $6/report.log
  fi
  
  cp $6/out.0.log $6/out."$1".1.log
  echo "Undeploy: $4"
  ant $4
  sleep $5
  diff $6/out."$1".1.log $6/out.0.log > $6/out."$1".undeploy.log
  
  # grep error
  ERRCOUNT=$(grep -ic " error " $6/out.$1.undeploy.log)

  printf "    %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)"
  printf "    %-30s | %-10s | %-20s\n" $1 "Undeploy" "$ERRCOUNT error(s)" >> $6/report.log
  if [ "$ERRCOUNT" != 0 ]
  then
    echo "" >> $6/report.log
    grep -i -A 4 -B 2 " error " $6/out.$1.undeploy.log >> $6/report.log
    echo -e "> ... see in file $6/out.$1.undeploy.log\n" >> $6/report.log
  fi
  
  cd ..
}

# Start JSLEE
export JBOSS_HOME=$HOME/jboss-5.1.0.GA
export SS7_STACK=$HOME/extra/mobicents-ss7/mobicents-jss7-3.0.1322/ss7
echo $JBOSS_HOME

rm -rf $HOME/deplog
mkdir deplog
$JBOSS_HOME/bin/run.sh > $HOME/deplog/out.0.log 2>&1 &
JBOSS_PID="$!"
echo "JBOSS: $JBOSS_PID"

sleep 30

echo -e "Deploy/Undeploy Report" >> $HOME/deplog/report.log

# Resources
echo -e "\nRAs:\n" >> $HOME/deplog/report.log

# Diameter
cd $HOME/resources
for dir in diameter*/
do
  dir=${dir%*/}
  echo ${dir##*/}
done

# SS7

# Install jSS7 Stack
cd $SS7_STACK
ant deploy
sleep 15

cd $HOME/resources
SS7_RA="map cap tcap isup"
for dir in $SS7_RA
do
  if [ $dir != "isup" ]
  then
    echo $dir
    check $dir deploy 10 undeploy 10 $HOME/deplog
  fi
done

# Uninstall jSS7 Stack
cd $SS7_STACK
ant undeploy
sleep 15

# Other
# Start SMPP Server for SMPP RA
cd $HOME/test-tools/smpp-server
java -cp smpp.server-0.0.1-SNAPSHOT.jar:lib/* org.mobicents.tools.smpp.server.ServerSMPP 2775 > $HOME/deplog/smpp.server.log 2>&1 &
SMPPSERVER_PID=$!
echo "SMPP Server: $SMPPSERVER_PID"

cd $HOME/resources
for dir in */
do
  dir=${dir%*/}
  if [ "$dir" == "${dir%diameter*}" ] && [ "${SS7_RA/$dir}" = "$SS7_RA" ]
  then
    echo "${dir} is not in Diameter and SS7"
    check $dir deploy 10 undeploy 10 $HOME/deplog
  fi
done

# Stop SMPP Server
kill -9 $SMPPSERVER_PID

# Examples
echo -e "\nExamples:\n" >> $HOME/deplog/report.log

cd $HOME/examples
for dir in */
do
  dir=${dir%*/}
  echo ${dir##*/}
  case $dir in
    call-controller2)
      check $dir deploy-all 10 undeploy-all 20 $HOME/deplog
      ;;
    slee-connectivity)
      check $dir deploy 10 undeploy 10 $HOME/deplog
      ;;
    google-talk-bot)
      ;;
    *)
      check $dir deploy-all 10 undeploy-all 10 $HOME/deplog
      ;;
  esac
done

# Enablers
echo -e "\nEnablers:\n" >> $HOME/deplog/report.log

cd $HOME/enablers
for dir in */
do
  dir=${dir%*/}
  if [ $dir != "hss-client" ]
  then
    echo $dir
    check $dir deploy-all 10 undeploy-all 10 $HOME/deplog
  fi
done

# Tools

rm -f $HOME/deplog/out.*.0.log
rm -f $HOME/deplog/out.*.1.log

pkill -TERM -P $JBOSS_PID
