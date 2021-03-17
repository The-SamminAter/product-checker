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
if [[ $(printf '%s' "$1" | cut -c1) == "-" ]]
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
	if [ $2 ]
	then
		name="$2"
		fCreate=true
	else
		#I figure that if this is being ran in silent mode, then it doesn't need color
		printf "[!] Error: while using silent mode, arg 2 can't be empty\n" #I can't have this printed to the file, because it hasn't been made yet
		exit
	fi
elif [ $1 ] && [ "${isArg}" == false ] #For if the script was launched with a name as an argument; doesn't currently work
then
	#Setting the background turned out to be iffy, so I'm just not doing it
	#printf "\e[40m" #Set a black background
	name="$1"
	if [ "$2" == "-y" ] || [ "$2" == "--yes" ]
	then
		fCreate=true
	elif [ "$2" == "-n" ] || [ "$2" == "--no" ]
	then
		fCreate=false
	fi
else
	#Setting the background turned out to be iffy, so I'm just not doing it
	#printf "\e[40m" #Set a black background
	if [ "$1" == "-y" ] || [ "$1" == "--yes" ]
	then
		fCreate=true
	elif [ "$1" == "-n" ] || [ "$1" == "--no" ]
	then
		fCreate=false
	fi
	#Title; sorry about the general messiness, I've tried to keep it relatively clean
	#printf "${RED}\n"
	printf "${RED}                                                   .-\"\"\"\"-.	\n"; #trick to show four quotation marks
	printf "                                                  /        \	\n"
	printf "${GRN}  _   _               ____                      ${RED} /_        _\	\n"
	printf "${GRN} | | | |___  ___ _ __|  _ \ ___  ___ ___  _ __  ${RED}// \      / \\"; echo "\\	" #cheap trick to show two back-slashes
	printf "${GRN} | | | / __|/ _ \ '__| |_) / _ \/ __/ _ \| '_ \ ${RED}|\__\    /__/|	\n"
	printf "${GRN} | |_| \__ \  __/ |  |  _ <  __/ (_| (_) | | | |${RED} \    ||    /	\n"
	printf "${GRN}  \___/|___/\___|_|  |_| \_\___|\___\___/|_| |_|${RED}  \        / 	\n"
	printf "${BLU} Reborn ${RED}----------------------------------- ${BLU}v0.9${RED}   \  __  /	\n"
	printf "                                                    '.__.'	\n"
	while [ "${name}" == "" ]
	do
		printf "${BLU}[?] Username: "
		read -p "" name
		#Add similar name(s) option
	done
fi


#File handling
if [ ${fCreate} ] #If fCreate exists, meaning it's already been set
then
	: #This just does nothing
else
	fCreate=false
	fCreateRaw=""
	printf "${BLU}[?] Do you want to save the output to a file: "
	read -p "" fCreateRaw
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


#This just lets the user know that the script is working, if silent mode isn't enabled
if [ "${silent}" == false ]
then
	printf "${BLU}[*] Checking for ${name}\n"
fi


#scan() scans URLs based on info passed to them, and outputs the results
#This was made with the assumption that if a name/page doesn't exist, it (the username) won't be mentioned anywhere in the curl'd text
#Also, the output (from scan()) is to be colored
scan()
{
	#Thought of/planned inputs
	#$1: name (of site)
	#$2: URL
	#$3: string to grep for (as an indication of success)
	#$4: any set var turns $3 into an indication of failure - only use if necessary
	#
	#Credit to https://stackoverflow.com/a/57120937 for 2>&1 for capturing curl's error
	#Also in use is a custom user agent, as curl/* doesn't work for some sites
	resultRaw=$(curl -s -S --show-error -A "UserRecon Reborn/0.0" "$2" 2>&1)
	if [[ $(echo "${resultRaw}" | head -c 5) == "curl:" ]]
	then
		print "error" "${resultRaw}"
	else
		result=$(echo "${resultRaw}" | grep "$3")
		if [ $4 ]
		then
			if [ -n "${result}" ]
			then
				status="failure"
			else
				status="success"
			fi
		else 
			if [ -n "${result}" ] 
			then
				status="success"
			else
				status="failure"
			fi
		fi
		print "${status}" "$1"
		unset status
	fi
}


#print() prints and writes (to fName) information passed to it by scan()
print()
{
	#$1: status message
	#$2: site name/error message (if $1 is "error")
	
	#Printing out the results (to the console) if the script isn't being ran in silent mode
	if [ "${silent}" == false ]
	then
		if [ "$1" == "success" ]
		then
			printf "${BLU}[${GRN}\xE2\x9C\x94${BLU}] ${GRN}$2 found\n"
		elif [ "$1" == "failure" ]
		then
			printf "${BLU}[${RED}X${BLU}] ${RED}$2 not found\n"
		elif [ "$1" == "error" ]
		then
			printf "${BLU}[${YLW}!${BLU}] ${YLW}Error: $2\n"
		fi
	fi
	#Printing out the results (to fName) if the user wants a file created
	if [ "${fCreate}" == true ]
	then
		if [ "$1" == "success" ]
		then
			printf "[\xE2\x9C\x94] $2 found\n" >> "${fName}"
		elif [ "$1" == "failure" ]
		then
			printf "[X] $2 not found\n" >> "${fName}"
		elif [ "$1" == "error" ]
		then
			printf "[!] Error: $2\n" >> "${fName}"
		fi
	fi
}


#URL checking:
#Arguments are explained

#Reddit                                                                                   
scan "Reddit" "https://api.reddit.com/user/${name}" "${name}"
