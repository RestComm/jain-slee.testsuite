#!/bin/bash
#export JSLEE=/opt/mobicents/restcomm-slee-2.8.17.46
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA

# Remove old nodes
echo "Remove old nodes port-1 and port-2"
rm -r $JBOSS_HOME/server/port-1
rm -r $JBOSS_HOME/server/port-2

# Create copy of /all
echo "Create copy of server/all to server/port-1 and server/port-2"
cp -r $JBOSS_HOME/server/all $JBOSS_HOME/server/port-1
cp -r $JBOSS_HOME/server/all $JBOSS_HOME/server/port-2

# Deploy/Install example: UAS, B2BUA
if [ $# -ne 0 ]; then
	case $1 in 
		uas-lb)
		    echo "Deploy UAS Example"
			ant deploy-all -f $JSLEE/examples/sip-uas/build.xml -Djboss.config=port-1
			ant deploy-all -f $JSLEE/examples/sip-uas/build.xml -Djboss.config=port-2
			
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-2 $LBTEST/deploy-config-2b.xml
			;;
		b2bua-lb)
		    echo "Deploy B2BUA Example"
			ant deploy-all -f $JSLEE/examples/sip-b2bua/build.xml -Djboss.config=port-1
			ant deploy-all -f $JSLEE/examples/sip-b2bua/build.xml -Djboss.config=port-2
		    
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-2 $LBTEST/deploy-config-2b.xml
			;;
    esac
fi

echo "Waiting 10 seconds"
sleep 10