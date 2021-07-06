checkDependencies () {        ##### Check if aircrack-ng is installed or not #####
if [ $(dpkg-query -W -f='${Status}' aircrack-ng 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
echo "Installing aircrack-ng\n\n"
sudo apt-get install aircrack-ng;
fi
}

checkWiFiStatus () {        ##### Check if wlan0 is enabled or not #####
WiFiStatus=`nmcli radio wifi`
if [ "$WiFiStatus" == "disabled" ]; then
nmcli radio wifi on
echo -e "[${Green}wlan0${White}] Enabled!"
fi
}


monitor () {        ##### Monitor mode, scan available networks & select target #####
  spinner &
  airmon-ng start wlan0 > /dev/null
  trap "airmon-ng stop wlan0mon > /dev/null;rm generated-01.kismet.csv handshake-01.cap 2> /dev/null" EXIT
  airodump-ng --output-format kismet --write generated wlan0mon > /dev/null & sleep 20 ; kill $!
  sed -i '1d' generated-01.kismet.csv
  kill %1
  echo -e "\n\n${Red}SerialNo        WiFi Network${White}"
  cut -d ";" -f 3 generated-01.kismet.csv | nl -n ln -w 8
  targetNumber=1000
  
  targetName=`sed -n "${targetNumber}p" < generated-01.kismet.csv | cut -d ";" -f 3 `
  bssid=`sed -n "${targetNumber}p" < generated-01.kismet.csv | cut -d ";" -f 4 `
  channel=`sed -n "${targetNumber}p" < generated-01.kismet.csv | cut -d ";" -f 6 `
  rm generated-01.kismet.csv 2> /dev/null
}
