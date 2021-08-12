# handshakecracker
## About
It's a bash script for collect handshakes in active and passive modes and sending its to hashcat server for cracking
## Requirements
- airmon-ng
- airodump-ng
- cap2hccapx
## Installation
All instructions are carried out in a chroot environment (e.g. kali linux)
### Utils
1. airodump-ng and airmon-ng (these utils contains in aircrack-ng package)
   * `Linux`
    ```
   sudo apt update  
   sudo apt install aircrack-ng
    ```
   
2. cap2hccapx
   git clone https://github.com/hashcat/hashcat-utils.git
   cd hashcat-utils/src
   make
   chmod +x cap2hccapx.bin
   cp cap2hccapx.bin /bin
 
