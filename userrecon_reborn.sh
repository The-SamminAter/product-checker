#!/bin/bash

#Coloring:
RST="\e[0;0m"
RED="\e[1;91m"
GRN="\e[1;92m" #1;32 or 1;92
BLU="\e[1;96m" #What's supposed to be blue looks purple so cyan (1;36 or 1;96) is used
YLW="\e[1;93m" #1;33 or 1;93


#If the user or the script exits (while not being ran in silent mode), this clears the colors
exitRST()
{
	if [ "${silent}" != true ]
	then
		printf "${RST}"
	fi
	printf ""
	exit
}
trap "exitRST" EXIT 


#Checks if $1 is an argument or not, mainly for use in the elif in name and argument handling
if [ $(printf '%s' "$1" | cut -c1) == "-" ]
then
	if [ "$1" == "-s" ] || [ "$1" == "--silent" ] || [ "$1" == "-y" ] || [ "$1" == "--yes" ] || [ "$1" == "-n" ] || [ "$1" == "--no" ]
	then
		isArg=true
	else
		isArg=false
	fi
else
	isArg=false
fi


#Name and argument handling
name=""
silent=false
if [[ "${isArg}" == true && "$1" == "-s" ]] || [[ "${isArg}" == true && "$1" == "--silent" ]] #Silent mode
then
	silent=true
	if [ "$2" ]
	then
		name="$2"
		fCreate=true
	else
		#I figure that if this is being ran in silent mode, then it doesn't need color
		printf "[!] Error: while using silent mode, arg 2 can't be empty\n"
		exit
	fi
elif [ $1 ] && [ "${isArg}" == false ] #For if the script was launched with a name as an argument; doesn't currently work
then
	printf "\e[40m" #Set a black background
	name="$1"
	if [ "$2" == "-y" ] || [ "$2" == "--yes" ]
	then
		fCreate=true
	elif [ "$2" == "-n" ] || [ "$2" == "--no" ]
	then
		fCreate=false
	fi
	printf "${BLU}Using ${name} as the username\n"
else
	printf "\e[40m" #Set a black background
	if [ "$1" == "-y" ] || [ "$1" == "--yes" ]
	then
		fCreate=true
	elif [ "$1" == "-n" ] || [ "$1" == "--no" ]
	then
		fCreate=false
	fi
	#Title; sorry about the general messiness, I've tried to keep it relatively clean
	#printf "${RED}\n"
	printf "${RED}                                                   .-\"\"\"\"-.	\n" #cheap trick to show four quotation marks
	printf "                                                  /        \	\n"
	printf "${GRN}  _   _               ____                      ${RED} /_        _\	\n"
	printf "${GRN} | | | |___  ___ _ __|  _ \ ___  ___ ___  _ __  ${RED}// \      / \\"; echo "\\" #cheap trick to show two back-slashes
	printf "${GRN} | | | / __|/ _ \ '__| |_) / _ \/ __/ _ \| '_ \ ${RED}|\__\    /__/|	\n"
	printf "${GRN} | |_| \__ \  __/ |  |  _ <  __/ (_| (_) | | | |${RED} \    ||    /	\n"
	printf "${GRN}  \___/|___/\___|_|  |_| \_\___|\___\___/|_| |_|${RED}  \        / 	\n"
	printf "${BLU} Reborn ${RED}----------------------------------- ${BLU}v0.0${RED}   \  __  /		\n"
	printf "                                                    '.__.'		\n"
	while [ "${name}" == "" ]
	do
		printf "${BLU}[${YLW}?${BLU}] ${YLW}Username:${RED}"
		read -p " " name
		#Add similar name(s) option; for example
	done
fi


#File handling
if [ ${fCreate} ] #If fCreate exists, meaning it's already been set
then
	: #This just does nothing
else
	fCreate=false
	fCreateRaw=""
	read -p "Do you want to save the output to a file? " fCreateRaw
	if [ "${fCreateRaw}" == "y" ] || [ "${fCreateRaw}" == "Y" ] || [ "${fCreateRaw}" == "Yes" ] || [ "${fCreateRaw}" == "yes" ] #I know, it's crude, but it works
	then
		fCreate=true
	fi
fi
if [ "${fCreate}" == true ]
then
	#fCount (and fName) are in place to prevent overwriting or adding on to a pre-existing file
	fCount=1
	fName="${name}-${fCount}.txt"
	while [ -f "./${fName}" ]
	do
		let "fCount++"
		fName="${name}-${fCount}.txt"
	done
	touch "${fName}"
fi


#scan() scans URLs based on info passed to them, and outputs the results
#This was made with the assumption that if a name/page doesn't exist, it (the username) won't be mentioned anywhere in the curl'd text
#Also, the output (from scan()) is to be colored
scan()
{
	#Thought of/planned inputs
	#$1: Name (of site)
	#$2: URL
	#$3: success text/message
	#$4: failure text/message (if necessary) (not yet written)
	#$5: additional error text/message (if necessary) (not yet written)
	status="If you see this, something is wrong"
	if [ "$4" ] || [ "$5" ]
	then
		echo "stub: scan(): if arg4 or arg5 exist"
	else
		result=$(curl -s -A "UserRecon Reborn/0.0" "$2" | grep "$3") #Custom user agent
		#if [ "${result}" != "" ] #Pretty much, if the result isn't nothing, we presume that it exists
		if [ -n "${result}" ]
		then
			status="success $1"
		else
			status="failure $1"
		fi
	fi
	print "${status}"
	unset status #Unsets the variable, so it doesn't exist until scan() gets called again
}


#print() prints and writes (to fName) information passed to it by scan()
print()
{
	echo "stub: print()"
}


#URL checking:

#Reddit
#Rejects the user agent curl/*
#cmd Name     URL                                                                                   
scan "Reddit" "https://api.reddit.com/user/${name}" "${name}"
