#!/bin/bash

interface=""
serverAddr=""

checkUtils(){
        printf "Check utilities...\n"

        #airmon-ng
        output=$(airmon-ng)
        if [[ "$output" == *"PHY"* ]]; then
                printf "airmon-ng....Done\n"
        else
                printf "airmon-ng....Fail\n"
        fi

        #airodump-ng
        output=$(airodump-ng)
        if [[ "$output" == *"usage: airodump-ng"* ]]; then
                printf "airodump-ng....Done\n"
        else
                printf "airodump-ng....Fail\n"
        fi
        printf "\n"
}


#checkServer(){}

#checkInterface(){}

getparams(){
        printf "Please set the wireless interface(e.g. wlan0):\n"
        read;
        interface=${REPLY}
        airmon-ng start $interface

        printf "Please set the hashcat server address(e.g. 192.168.1.24:9000)\n"
        read;
        serverAddr=${REPLY}

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
