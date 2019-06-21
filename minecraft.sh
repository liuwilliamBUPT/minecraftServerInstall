#!/bin/bash

# This function is used to check whether the input is numbers. It accept sstring arguments and its numbers will be replaced with regulars.
checkInt(){
tmp=$(echo $1|sed 's/[0-9]//g')
if [ -n "${tmp}" ]; then
	return 0
else
	return 1
fi
}

# This function is used to execute sudo command.
sudoExec(){
if $sudo_flag; then
	local cmd='sudo '
	cmd+=$@
	eval $cmd
	return $?
else
	eval $1
	return $?
fi
}

# TODO: parse arguments. 

echo -e "\033[1;44;37mCheck installation status of java. Notice that this script will check openjdk-8-jdk-headless install status.\033[0m\n"

# Detecting sudo status.
if dpkg --get-selections | grep sudo ; then
	sudo_flag=true
else
	sudo_flag=false
fi

# Installing openjdk-8-jdk-headles.

geoip=$(curl -s https://api.ip.sb/geoip)
if echo $ip | grep '"country_code":"CN"' >/dev/null 2>&1; then
	CN=true
else
	CN=false
fi

checkPackage='apt search openjdk-8-jdk-headless | grep openjdk-8-jdk-headless'

if ! sudoExec $checkPackage; then
	apt_repo='apt-get install software-properties-common python-software-properties -y'
	sudoExec $apt_repo
	sudoExec 'add-apt-repository ppa:openjdk-r/ppa -y'
	if CN; then
		changePPA='sed -i "s/ppa\\.launchpad\\.net/launchpad\\.proxy\\.ustclug\\.org/g" /etc/apt/sources.list.d/openjdk-r-ubuntu-ppa-*.list'
		sudoExec $changePPA
	fi
fi

sudoExec 'apt update'

if dpkg --get-selections | grep openjdk-8-jdk-headless; then
	echo -e "\033[1;44;37mPackage openjdk-8-jdk-headless have been installed.\033[0m\n"
else
	echo -e "\033[1;44;37mInstalling openjdk-8-jdk-headless... \033[0m"
	sudoExec 'apt update && apt install -y openjdk-8-jdk-headless'
	echo -e "\033[1;44;37mPackage openjdk-8-jdk-headless installed. \033[0m"
fi

echo -e "\033[1;44;37mCreate minecraft directory.\033[0m\n"

if [ ! -d ~/minecraft ]; then
	mkdir minecraft
fi

cd minecraft || cd ~/minecraft || return 255
if [ $? = 255 ]; then echo -e "\033[1;44;37mNo such Directory!\033[0m";fi

# Set a flag to detect whether to download a new minecraft server.


if [ -f ~/minecraft/minecraft_server.*.jar ]; then
	tempver=$(find ~/minecraft/minecraft_server.*.jar | awk -F[\.] '{print $2"."$3"."$4}')
	# Store the existed minecraft server version in tempver.
	echo -n "Detecting that there exists minecraft_server.${tempver}.jar, do you want to get a new one?(Y/n)[Default = N]:"
	read judge
	echo -e '\n'
	if [ -z $judge ];then
		judge='N'
	fi
	case $judge in
	Y | y)
		rm minecraft_server.$tempver.jar
		flag=1
		;;
	N | n)
		flag=0
		version=$tempver
		;;
	esac
else
	flag=1
fi

# Handling flag.
if [ $flag -eq 1 ]; then
	echo -n "Chose the version(default = 1.12.2) you want to use:"
	read version
	echo -e '\n'
	if [ -z $version ];then
		version='1.12.2'
	fi
	wget --header="Host: s3.amazonaws.com" \
	--header="Connection: keep-alive" \
	--header="Upgrade-Insecure-Requests: 1" \
	--header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36" \
	--header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
	--header="Accept-Encoding: gzip, deflate, br" \
	--header="Accept-Language: zh-CN,zh;q=0.9,fr;q=0.8,zh-TW;q=0.7" \
	"https://s3.amazonaws.com/Minecraft.Download/versions/"$version"/minecraft_server."$version".jar"
fi

# The above url may be invalid in the future.

# Use loop to ensure the input strings are numeric.
noticeFlag=true
while true
do
	if $noticeFlag; then
		echo -e "\033[1;44;37mNotice:You can use Ctrl + Backspace to delete error entry.\033[0m\n"
		noticeFlag=false
	fi
	read -p "Set the minimum memory and maximum memory, example:1024 1024:" minmem maxmem
	
	if [ -z $maxmem ]; then
		check=0
	elif [ -z $minmem ]; then
		check=0
	else
		check=1
	fi
	
	# Use maxS and minS to monitor the maxmem and minmen input status.
	checkInt $maxmem
	maxS=$?
	checkInt $minmem
	minS=$?

	if [[ $check -eq 0 ]]; then
		echo -e "\033[1;44;37mPlease enter the correct setting!\033[0m"
		# if check is not equal to 0 
	elif [[ $maxS -eq 0 || $minS -eq 0 ]]; then
		# if maxS or minS 
		echo -e "\033[1;44;37mPlease make sure you what you entered are numbers!\033[0m"
	else
		break
	fi
done
# Check the installation status of the expect.
echo -e "\033[1;44;37mCheck the installation status of the expect.\033[0m\n"
dpkg --get-selections | grep expect
if [ $? -ne 0 ]; then
	echo -e "\033[1;44;37mInstalling expect...\033[0m\n"
	installExpect='apt install -y expect >/dev/null 2>&1'
	sudoExec $installExpect
fi

# First, check the existation of the gameInit.exp. If not, check eula.txt...

# Check if eual.txt exists.
if [ ! -f ~/minecraft/eula.txt ]; then
	# If not, create gameInit.exp to firstly launch mc, and this file will be created automatically.
	# RTFM to learn how to use expect wisely.
	cat > ~/minecraft/gameInit.exp<<EOF
#!/usr/bin/expect -f
set timeout 30
set maxmem [lindex $argv 0]
set minmem [lindex $argv 1]
set version [lindex $argv 2]
cd ~/minecraft
echo -e "\033[1;44;37mFirst running minecraft.\033[0m\n"
spawn java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.${version}.jar nogui
expect "*Stopping*" {exec sh -c {
touch finised
}}
EOF
	# success？
	temp=$?
	
	# This may dosen't work?
		
	if [ $temp -eq 0 ]; then

		chmod 700 ~/minecraft/gameInit.exp
		expect ~/minecraft/gameInit.exp $maxmem $minmem $version
		sed -i 's/eula=false/eula=true/g' ~/minecraft/eula.txt
		sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
	fi
else
	# Else check whether the files have been modified.
	cat ~/minecraft/eula.txt | grep eula=true >/dev/null 2>&1 
	if [ $? -eq 0 ];then
		echo -e "\033[1;44;37mDetect that there you might have run minecraft_server.${version}.jar successfully.\033[0m\n"
	else
		echo -e "\033[1;44;37mModify eula.txt and server.properties now.\033[0m\n"
		sed -i 's/eula=false/eula=true/g' ~/minecraft/eula.txt
		sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
		rm gameInit.exp
	fi
fi


cat > ~/minecraft/gameInit.exp<<EOF
#!/usr/bin/expect -f
set timeout 30
set maxmem [lindex $argv 0]
set minmem [lindex $argv 1]
set version [lindex $argv 2]
cd ~/minecraft 

spawn java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.${version}.jar nogui
expect "*Done*" {
send "stop\r"
exec sh -c {
touch finised
}}
EOF
if [ $? -eq 0 ]; then
	chmod 700 ~/minecraft/gameInit.exp
	expect ~/minecraft/gameInit.exp $maxmem $minmem $version
fi
while [ ! $? ]
do
	sleep 1s
done
rm gameInit.exp finised
# java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.jar nogui
# if [ -z $version ];then
# 	$version='1.12.2'
# fi
forgeversion="1.12.2-14.23.5.2812"
# add set up 
if [ ! -f ~/minecraft/forge-*-universal.jar ];then
	# wget -O forgeInstaller.jar https://files.minecraftforge.net/maven/net/minecraftforge/forge/$forgeversion/forge-$forgeversion-installer.jar
	# java -jar forgeInstaller.jar nogui --installServer --offline
	echo -e "\033[1;44;37mDownloading forge installer.\033[0m\n"
	wget https://files.minecraftforge.net/maven/net/minecraftforge/forge/$forgeversion/forge-$forgeversion-installer.jar
	echo -e "\033[1;44;37mInstalling forge.\033[0m\n"
	java -jar forge-$forgeversion-installer.jar nogui --installServer
	# rm forgeInstaller.jar forgeInstaller.jar.log
fi

sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
echo -e "\033[1;44;37mRuning forge server!\033[0m\n"
java -Xmx${maxmem}M -Xms${minmem}M -jar forge-$forgeversion-universal.jar nogui
