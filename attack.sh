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
                \033[31m <your text goes here> \033[0m
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
                printf "cap2hccapx...\033[32m Done\033[0m\n"
        else
                printf "cap2hccapx....\033[31m Fail \033[0m\n"
                exit 1
        fi

        printf "\n"
}


checkServer(){
        curl http://$serverAddr/handshakes > /dev/null
        if [[ $? == 0 ]]; then
                echo "Server status - working"
        else
                echo "Server status - not working"
                exit 1
        fi
}

#checkInterface(){}

getparams(){
        printf "Please set the wireless interface(e.g. wlan0):\n"
        read;
        interface=${REPLY}
        airmon-ng start $interface

        printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\n"
        read;
        serverAddr=${REPLY}
        checkServer

        printf "Please set the attack mode(active or passive)\n"
        read;
        mode=${REPLY}
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
