#!/bin/bash
#export JSLEE=/opt/restcomm/restcomm-slee-2.8.14.40
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA

# Remove old nodes
rm -r $JBOSS_HOME/server/port-1
rm -r $JBOSS_HOME/server/port-2

# Create copy of /all
cp -r $JBOSS_HOME/server/all $JBOSS_HOME/server/port-1
cp -r $JBOSS_HOME/server/all $JBOSS_HOME/server/port-2

# Deploy/Install example: UAS, B2BUA
if [ $# -ne 0 ]; then
	case $1 in	
		uas)
			ant deploy-all -f $JSLEE/examples/sip-uas/build.xml -Djboss.config=port-1
			ant deploy-all -f $JSLEE/examples/sip-uas/build.xml -Djboss.config=port-2
			
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-2 $LBTEST/deploy-config-2b.xml
			;;
		b2bua)
			ant deploy-all -f $JSLEE/examples/sip-b2bua/build.xml -Djboss.config=port-1
			ant deploy-all -f $JSLEE/examples/sip-b2bua/build.xml -Djboss.config=port-2
		    
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $JBOSS_HOME/server/port-2 $LBTEST/deploy-config-2b.xml
			;;
    esac
fi
