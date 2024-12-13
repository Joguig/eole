sudo echo "deb [ arch=amd64 ] http://apt.van-belle.nl/debian bionic-samba411 main contrib non-free" >/etc/apt/sources.list.d/seth-samba.list
wget -O /tmp/louis-van-belle.gpg-key.asc http://apt.van-belle.nl/louis-van-belle.gpg-key.asc 
sudo apt-key add /tmp/louis-van-belle.gpg-key.asc
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y samba
sudo apt-get autoremove -y

