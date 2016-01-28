#!/bin/bash
# $1 - path to Node
# $2 - new deploy-config.xml

export TEST=$PWD
export NODE1=$1 #/opt/mobicents/mobicents-slee-2.8.14.40/jboss-5.1.0.GA/server/port-1

export SIP11RAPATH=$NODE1/deploy/sip11-ra-DU-*.jar
export SIP11RA=$(basename $SIP11RAPATH)
export SIP11RA="${SIP11RA%.*}"

echo "Updating SIP RA jar file with $2"
cd $NODE1/deploy
unzip -q $SIP11RA.jar -d $SIP11RA
rm -f $SIP11RA.jar

#echo "2"
cd $SIP11RA/META-INF
rm deploy-config.xml
cp $TEST/$2 deploy-config.xml

#echo "3"
cd $NODE1/deploy/$SIP11RA
zip -qr ../$SIP11RA.jar *
cd ..
rm -rf $SIP11RA
