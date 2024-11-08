#!/bin/bash
# Check Dongle Connection Status
# Original https://dekuo-03.hatenablog.jp/entry/2021/01/09/174623

CONNECTION=$1 # Connection Name
INTERVAL=$2 # Checking Interval [sec]
WAITING_TIME=$3 # Waiting Time for Connection Establish [sec]

echo "Connection Name: $CONNECTION"
echo "Check Interval: $INTERVAL [sec]"
echo "Waiting $WAITING_TIME [sec]..."

sleep $WAITING_TIME

while true
do
	# Get IPv4 Address
	ipv4_address=`nmcli c show $CONNECTION | grep IP4.ADDRESS`
	
	if [ "$ipv4_address" == "" ]; then
		echo "Disconnect Detected"
		# When IPv4 Address is "", Connect Again.
		nmcli c up $CONNECTION
	#	else
	#		echo "Alive!!! $ipv4_address"
	fi

	sleep $INTERVAL
done