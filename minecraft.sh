#!/bin/bash
#use current path to subsitute ~/
#This function is used to check whether the input is numbers.
checkInt(){
tmp=$(echo $1|sed 's/[0-9]//g')
if [ -n "${tmp}" ]; then
	return 0
else
	return 1
fi
}

echo 'Check java install status.Notice that this script will only check openjdk-8-jdk-headless install status.'



#change to install jdk8 sudo apt install openjdk-8-jdk-headless

if dpkg --get-selections | grep openjdk-8-jdk-headless; then
	
	if sudo apt-get update 2>/dev/null && sudo apt-get install -y openjdk-8-jdk-headless 2>/dev/null; then
	apt-get update && apt-get install -y openjdk-8-jdk-headless
	fi
fi
#sudo may not install
if [ ! -d ~/minecraft ]; then
	mkdir minecraft
fi
cd minecraft || cd ~/minecraft || return 255
flag=0
if [ -f ~/minecraft/minecraft_server.*.jar ]; then
	tempver=$(find ~/minecraft/minecraft_server.*.jar | awk -F[\.] '{print $2"."$3"."$4}')
	echo -n "Detect that there exists minecraft_server.${tempver}.jar, do you want to get a new one?(Y/n)[Default = N]:"
	read judge
	if [ -z $judge ];then
		judge='N'
	fi
	case $judge in
	Y | y)
		rm minecraft_server.$tempver.jar
		flag=1
		;;
	N | n)
		:
		;;
	esac
else
	flag=1
fi

if [ $flag -eq 1 ]; then
	echo -n "Chose the version(default = 1.12.2) you want to use:"
	read version
	if [ -z $version ];then
		version='1.12.2'
	fi
	cd minecraft || cd ~/minecraft || return 255
	#wget -O minecraft_server.jar https://s3.amazonaws.com/Minecraft.Download/versions/$version/minecraft_server.$version.jar
	wget https://s3.amazonaws.com/Minecraft.Download/versions/$version/minecraft_server.$version.jar
fi

# The above url may be invalid in the future.

while true
do
	read -p "Set mem max and min usage, example:1024 1024:" maxmem minmem
	#If you make an input mistake, use Ctrl + Backspace to delete that.
	#whether how much args this will return 0
	#echo $maxmem $minmem
	if [ -z $maxmem ]; then
		check=0
	elif [ -z $minmem ]; then
		check=0
	else
		check=1
	fi
	#echo $check
	checkInt $maxmem
	maxS=$?
	checkInt $minmem
	minS=$?
	#problem 0 input or 1 input this loop will exit.
	if [[ $check -eq 0 ]]; then
		echo "Please enter the memory setting!"
		#if check is not equal to 0 
	elif [[ $maxS -eq 0 || $minS -eq 0 ]]; then
		#if maxS or minS 
		echo "Please make sure you what you entered are numbers!"
	else
		break
	fi
done
dpkg --get-selections | grep expect
if [ $? -ne 0 ]; then
	sudo apt-get install -y expect 2>/dev/null
	if [ $? -ne 0 ]; then
	apt-get install -y expect
	fi
fi

#the part after here not execute
#First, to check if the game.sh exists. If not, check eula.txt...
echo "First, to check if the game.sh exists. If not, check eula.txt..."
echo -n "just for stop,ready to cat > ~/minecraft/game.sh" nothing
read nothing

if [ ! -f ~/minecraft/eula.txt ]; then
	cat > ~/minecraft/game.sh<<EOF
#!/usr/bin/expect
set timeout 30
set maxmem [lindex $argv 0]
set minmem [lindex $argv 1]
ser version [lindex $argv 2]
cd ~/minecraft
spawn java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.${version}.jar nogui
expect "*Stopping*"
EOF
	temp=$?
	echo -n "just for stop ,execute game.sh" nothing
	read nothing
		
	if [ $temp -eq 0 ]; then

		chmod 700 ~/minecraft/game.sh
		expect -f ~/minecraft/game.sh $maxmem $minmem $version
		if [ -f finished ]; then
			sed -i 's/eula=false/eula=true/g' ~/minecraft/eula.txt
			sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
		fi
	fi	
else
	cat ~/minecraft/eula.txt | grep eula=true >/dev/null 2>&1 
	if [ $? -eq 0 ];then
		echo -n "Detect that there you might have run minecraft_server.${version}.jar successfully."
	else
		echo -n "just for stop, change eula" nothing
		read nothing
		sed -i 's/eula=false/eula=true/g' ~/minecraft/eula.txt
		sed -i 's/online-mode=true/online-mode=false/g' ~/minecraft/server.properties
		rm game.sh
	fi
fi

echo -n "just for stop change eula finished" nothing
read nothing
cat > ~/minecraft/game.sh<<EOF
#!/usr/bin/expect
set timeout 30
set maxmem [lindex $argv 0]
set minmem [lindex $argv 1]
ser version [lindex $argv 2]
cd ~/minecraft 

spawn java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.${version}.jar nogui
expect "*Done*" {send "stop\r"}
touch finished
EOF
if [ $? -eq 0 ]; then
	chmod 700 ~/minecraft/game.sh
	expect -f ~/minecraft/game.sh $maxmem $minmem $version
fi
while [ ! $? ]
do
	sleep 1s
done
rm game.sh
#java -Xmx${maxmem}M -Xms${minmem}M -jar minecraft_server.jar nogui
#if [ -z $version ];then
#	$version='1.12.2'
#fi
forgeversion="1.12.2-14.23.5.2812"
if [ ! -f ~/minecraft/forge-*-universal.jar ];then
	wget -O forgeInstaller.jar https://files.minecraftforge.net/maven/net/minecraftforge/forge/$forgeversion/forge-$forgeversion-installer.jar
	java -jar forgeInstaller.jar nogui --installServer --offline
	rm forgeInstaller.jar forgeInstaller.jar.log
fi

java -Xmx${maxmem}M -Xms${minmem}M -jar forge-$forgeversion-universal.jar nogui
