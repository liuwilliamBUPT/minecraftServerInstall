#!/bin/bash

# This function is used to check whether the input is numbers.Accept string arguments and replace numbers with regulars.Then check whether the ${tmp} is null.
checkInt(){
tmp=$(echo $1|sed 's/[0-9]//g')
if [ -n "${tmp}" ]; then
	return 0
else
	return 1
fi
}


echo 'Check installation status of java. Please note that this script will just check installation status of openjdk-8-jdk-headless.'


# change to install jdk8 sudo apt install openjdk-8-jdk-headless
# maybe change here to case.
if dpkg --get-selections | grep openjdk-8-jdk-headless; then
	echo "Package openjdk-8-jdk-headless have been installed."
else
	echo "Installing openjdk-8-jdk-headless... "
	if ! sudo apt-get update 2>/dev/null && ! sudo apt-get install -y openjdk-8-jdk-headless 2>/dev/null; then
	apt-get update && apt-get install -y openjdk-8-jdk-headless
	echo "Package openjdk-8-jdk-headless installed. "
	fi
fi

# sudo may not install
echo -n "Please speicify the path to install minecraft:"
read installPath

if [ ! -d ~/minecraft ]; then
    echo "Create minecraft directory."
	mkdir minecraft
fi

cd minecraft || cd ~/minecraft || return 255
if [ $? = 255 ]; then echo "No such Directory!";fi

# Set a flag to detect whether to download a new minecraft server.


if [ -f ~/minecraft/minecraft_server.*.jar ]; then
	tempver=$(find ~/minecraft/minecraft_server.*.jar | awk -F[\.] '{print $2"."$3"."$4}')
	# Store the existed minecraft server version in tempver.
	echo -n "Detect that there exists minecraft_server.${tempver}.jar, do you want to get a new one?(Y/n)[Default = N]:"
	read judge
	if [ -z ${judge} ];then
		judge='N'
	fi
	case ${judge} in
	Y | y)
		rm minecraft_server.${tempver}.jar
		flag=1
		;;
	N | n)
		flag=0
		version=${tempver}
		;;
	esac
else
	flag=1
fi

# handle flag.
if [ ${flag} -eq 1 ]; then
	echo -n "Chose the version(default = 1.12.2) you want to use:"
	read version
	if [ -z ${version} ];then
		version='1.12.2'
	fi
	# dupe cd minecraft || cd ~/minecraft || return 255
	# wget -O minecraft_server.jar https://s3.amazonaws.com/Minecraft.Download/versions/$version/minecraft_server.$version.jar
	# wget https://s3.amazonaws.com/Minecraft.Download/versions/$version/minecraft_server.$version.jar
	wget --header="Host: s3.amazonaws.com" \
	--header="Connection: keep-alive" \
	--header="Upgrade-Insecure-Requests: 1" \
	--header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36" \
	--header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
	--header="Accept-Encoding: gzip, deflate, br" \
	--header="Accept-Language: zh-CN,zh;q=0.9,fr;q=0.8,zh-TW;q=0.7" \
	"https://s3.amazonaws.com/Minecraft.Download/versions/"${version}"/minecraft_server."${version}".jar"
fi

# The above url may be invalid in the future.

# Use loop to ensure the input strings are numeric.
while true
do
	echo "Notice:You can use Ctrl + Backspace to delete error entry."
	read -p "Set the minimum memory and maximum memory, example:1024 1024:" minmem maxmem
	# If you make an input mistake, use Ctrl + Backspace to delete that.
	# whether how much args this will return 0
	# echo $maxmem $minmem
	if [ -z ${maxmem} ]; then
		check=0
	elif [ -z ${minmem} ]; then
		check=0
	else
		check=1
	fi
	# Use maxS and minS to monitor the maxmem and minmen input status.
	checkInt ${maxmem}
	maxS=$?
	checkInt ${minmem}
	minS=$?
	# Problem is that 0 input or 1 input this loop will exit. This may fixed?
	if [[ ${check} -eq 0 ]]; then
		echo "Please enter the memory setting!"
		# if check is not equal to 0
	elif [[ ${maxS} -eq 0 || ${minS} -eq 0 ]]; then
		# if maxS or minS
		echo "Please make sure you what you entered are numbers!"
	else
		break
	fi
done
# Check the installation status of the expect.
echo "Check the installation status of the expect."
dpkg --get-selections | grep expect
if [ $? -ne 0 ]; then
	echo "Installing expect..."
	sudo apt-get install -y expect 2>/dev/null
	if [ $? -ne 0 ]; then
	echo "Installing expect..."
	apt-get install -y expect
	fi
fi

# The part below is still on testing.
# First, to check if the gameInit.exp exists. If not, check eula.txt...
# echo "First, to check if the gameInit.exp exists. If not, check eula.txt..."
# echo -n "just for stop,ready to cat > ~/minecraft/gameInit.exp" nothing
# read nothing

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
spawn java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.${version}.jar nogui
expect "*Stopping*" {exec sh -c {
touch finised
}}
EOF
	# echo '#! /usr/bin/expect -f
	# puts aaa' >flagf.exp
	# success？
	temp=$?

	# This may dosen't work?

	if [ ${temp} -eq 0 ]; then

		chmod 700 ~/minecraft/gameInit.exp
		expect ~/minecraft/gameInit.exp ${maxmem} ${minmem} ${version}
		sed -i 's/eula=false/eula=true/g' ~/minecraft/eula.txt
		sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
	fi
else
	# Else check whether the files have been modified.
	cat ~/minecraft/eula.txt | grep eula=true >/dev/null 2>&1
	if [ $? -eq 0 ];then
		echo -n "Detect that there you might have run minecraft_server.${version}.jar successfully."
	else
		echo "Modify eula.txt and server.properties now."
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
	expect ~/minecraft/gameInit.exp ${maxmem} ${minmem} ${version}
fi
while [ ! $? ]
do
	sleep 1s
done
rm gameInit.exp finised
# java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.jar nogui
# if [ -z $version ];then
#  	$version='1.12.2'
# fi
forgeversion="1.12.2-14.23.5.2812"
# add set up
if [ ! -f ~/minecraft/forge-*-universal.jar ];then
	# wget -O forgeInstaller.jar https://files.minecraftforge.net/maven/net/minecraftforge/forge/$forgeversion/forge-$forgeversion-installer.jar
	# java -jar forgeInstaller.jar nogui --installServer --offline
	wget https://files.minecraftforge.net/maven/net/minecraftforge/forge/${forgeversion}/forge-${forgeversion}-installer.jar
	java -jar forge-${forgeversion}-installer.jar nogui --installServer
	# rm forgeInstaller.jar forgeInstaller.jar.log
fi

java -Xmx${maxmem}M -Xms${minmem}M -jar forge-${forgeversion}-universal.jar nogui
