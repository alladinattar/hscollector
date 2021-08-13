# hscollector
## About
It's a bash script for collect handshakes in active and passive modes and sending its to hashcat server for cracking
## Required hardware
- Android Phone
- External Wi-Fi adapter
## Required utilities
### Phone
- airmon-ng
- airodump-ng
- cap2hccapx
## Installation
All instructions are carried out in a chroot environment (e.g. kali linux)
### Utils
1. airodump-ng and airmon-ng (these utils contains in aircrack-ng package)
    ```
   sudo apt update  
   sudo apt install aircrack-ng
    ```
2. cap2hccapx
    ```
   git clone https://github.com/hashcat/hashcat-utils.git
   cd hashcat-utils/src
   make
   chmod +x cap2hccapx.bin
   cp cap2hccapx.bin /bin/cap2hccapx
    ```
## Usage
```
    ./attack.sh [ p|a ] addr
```
   a - active mode  
   p - passive mode  
   addr - hashcat server address
 
