#!/bin/bash

# Remove old nodes
echo "Remove old nodes server1 and server2"
rm -Rf $SERVER1
rm -Rf $SERVER2

# Create copy of /all
echo "Creating copies for server1 and server2"
cp -r $JSLEE_HOME $SERVER1
cp -r $JSLEE_HOME $SERVER2

# change rmi address for second server
sed -i 's/name=\"rmiAddress\" value=\"127.0.0.1\"/name=\"rmiAddress\" value=\"127.0.0.2\"/g' $SERVER2/wildfly-10.1.0.Final/standalone/configuration/standalone.xml
sed -i 's/name=\"rmiAddress\" value=\"127.0.0.1\"/name=\"rmiAddress\" value=\"127.0.0.2\"/g' $SERVER2/wildfly-10.1.0.Final/standalone/configuration/standalone-ha.xml

# Deploy/Install example: UAS, B2BUA
if [ $# -ne 0 ]; then
	case $1 in 
		uas-lb)
		    echo "Deploy UAS Example"
			ant deploy-all -f $SERVER1/examples/sip-uas/build.xml
			ant deploy-all -f $SERVER2/examples/sip-uas/build.xml
			
			sh $LBTEST/update-sip-ra.sh $SERVER1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $SERVER2 $LBTEST/deploy-config-2b.xml
			;;
		b2bua-lb)
		    echo "Deploy B2BUA Example"
			ant deploy-all -f $SERVER1/examples/sip-b2bua/build.xml
			ant deploy-all -f $SERVER2/examples/sip-b2bua/build.xml
		    
			sh $LBTEST/update-sip-ra.sh $SERVER1 $LBTEST/deploy-config-1b.xml
			sh $LBTEST/update-sip-ra.sh $SERVER2 $LBTEST/deploy-config-2b.xml
			;;
    esac
fi

echo "Waiting 10 seconds"
sleep 10
