#!/bin/bash
#export JSLEE=/opt/mobicents/restcomm-slee-2.8.17.46
#export JBOSS_HOME=$JSLEE/jboss-5.1.0.GA

# Remove old nodes
echo "Remove old nodes port-1 and port-2"
rm -Rf $LB_HOME1
rm -Rf $LB_HOME2

# Create copy of /all
echo "Create copy of server/all to server/port-1 and server/port-2"
cp -R $JSLEE_HOME $LB_HOME1
cp -R $JSLEE_HOME $LB_HOME2

# Deploy/Install example: UAS, B2BUA
if [ $# -ne 0 ]; then
	case $1 in 
		uas-lb)
		    echo "Deploy UAS Example"
			ant deploy-all -f $LB_HOME1/examples/sip-uas/build.xml -Djboss.config=default
			ant deploy-all -f $LB_HOME2/examples/sip-uas/build.xml -Djboss.config=default
			
			sh $LBTEST/update-sip-ra.sh $LB_JBOSS1/server/default $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $LB_JBOSS2/server/default $LBTEST/deploy-config-2b.xml
			;;
		b2bua-lb)
		    echo "Deploy B2BUA Example"
			ant deploy-all -f $LB_HOME1/examples/sip-b2bua/build.xml -Djboss.config=default
			ant deploy-all -f $LB_HOME2/examples/sip-b2bua/build.xml -Djboss.config=default
		    
			sh $LBTEST/update-sip-ra.sh $LB_JBOSS1/server/default $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $LB_JBOSS2/server/default $LBTEST/deploy-config-2b.xml
			;;
    esac
fi

echo "Waiting 10 seconds"
sleep 10
