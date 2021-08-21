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

#checkInterface(){}

getparams(){
        printf "Please select an action:\n"
        printf "1) Start active attack\n2) Start passive attack\n3) Get crack results\n"
        read;
        re='^[0-9]+$'
        if ! [[ ${REPLY} =~ $re ]] || [[ ${REPLY} >3 ]]; then
                printf "Invalid input.\n"
                getparams
        fi

        if [[ ${REPLY} == 1 ]] || [[ ${REPLY} == 2 ]] ;then
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
        else if [[ ${REPLY} == 3 ]];then
                printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\n"
                read;
                serverAddr=${REPLY}
                checkServer
        fi
        fi

}

cleanup(){
        rm /home/kali/hscollector/shakes-* &> /dev/null
}

trap cleanup SIGINT SIGTERM ERR EXIT

main(){
        checkUtils
        getparams
}
main
