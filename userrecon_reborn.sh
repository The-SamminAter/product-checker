#!/bin/bash

#Version
version="v0.10"

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


#This just checks if $1 is a known argument
if [[ $(printf '%s' "$1" | cut -c1) == "-" ]]
then
	#There's got to be a simpler and better way to do this, but using [[ "$1" == @("-y"|"--yes") ]] requires bash 4.2 or higher
	if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-s" ] || [ "$1" == "--silent" ] || [ "$1" == "-y" ] || [ "$1" == "--yes" ] || [ "$1" == "-n" ] || [ "$1" == "--no" ]
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
if [[ "${isArg}" == true && "$1" == "-h" ]] || [[ "${isArg}" == true && "$1" == "--help" ]] #Help dialogue
then
	echo "UserRecon Reborn ${version} - help dialogue:"
	echo "Usage: ./userrecon_reborn.sh [argument] <name>"
	echo ""
	echo "Arguments:"
	echo " -h, --help    Displays this help dialogue"
	echo " -s, --silent  Enables silent mode, which silently saves output a local file"
	echo " -y, --yes     Enables writing the output to a local file"
	echo " -n, --no      Disables writing the output to a local file"
	echo ""
	echo "Local file naming:"
	echo " If enabled, a file named name-x.txt in the current directory will be created and written to, where 'name' is the name scanned for, and 'x' is a number, 1 or higher, to prevent overwriting of previous scans"
	echo ""
	echo "Homepage: <https://github.com/the-samminater/userrecon_reborn>"
	exit
elif [[ "${isArg}" == true && "$1" == "-s" ]] || [[ "${isArg}" == true && "$1" == "--silent" ]] #Silent mode
then
	silent=true
	if [ $2 ]
	then
		name="$2"
		fCreate=true
	else
		#I figure that if this is being ran in silent mode, then it doesn't need color
		echo "[!] Error: while using silent mode, <arg2> can't be empty" #I can't have this printed to the file, because it (the file) hasn't been made yet
		exit
	fi
else
	if [ "$1" ] #If the script is ran with at least one argument
	then
		if [ "${isArg}" == true ] #And if the first argument is a recognized argument
		then
			if [ "$1" == "-y" ] || [ "$1" == "--yes" ]
			then
				fCreate=true
			elif [ "$1" == "-n" ] || [ "$1" == "--no" ]
			then
				fCreate=false
			fi
			if [ $2 ] #If there's a second argument, presume it's a name
			then
				name="$2"
			fi
		else #Presume that the first argument is a name
			name="$1"
			if [ $2 ]
			then
				#if [[ "$2" == @("-y"|"--yes") ]] #Requires bash v4.2 or later
				if [ "$2" == "-y" ] || [ "$2" == "--yes" ]
				then
					fCreate=true
				elif [ "$2" == "-n" ] || [ "$2" == "--no" ]
				then
					fCreate=false
				fi
			fi
		fi
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
	printf "${BLU} Reborn ${RED}---------------------------------- ${BLU}${version}${RED}   \  __  /	\n"
	printf "                                                    '.__.'	\n"
	if [ "${name}" == "" ]
	then
		while [ "${name}" == "" ]
		do
			printf "${BLU}[?] Name: "
			read -p "" name
			#To-do: add similar name(s) option
		done
	else
		printf "${BLU}[?] Name: ${name}\n"
	fi
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


#scan() scans URLs based on info passed to it, determines if the profile exists or not, and then passes that on to print()
scan()
{
	#$1: name (of site)
	#$2: URL
	#$3: string to grep for (as an indication of success)
	#$4: if set to -i (as in inverse), turns $3 into an indication of failure - only use if necessary
	#$5: Headers (if necessary)
	#
	#Credit to https://stackoverflow.com/a/57120937 for 2>&1 for capturing curl's error
	#Also in use is a custom user agent, as curl/* doesn't work for some sites
	if [ "$5" ] #In the case that a header is necessary
	then
		resultRaw=$(curl -s -S --show-error -A "UserRecon Reborn/${version}" "$2" -H "$5" 2>&1)
	else
		resultRaw=$(curl -s -S --show-error -A "UserRecon Reborn/${version}" "$2" 2>&1)
	fi
	if [[ $(echo "${resultRaw}" | head -c 5) == "curl:" ]] #Need to change to deal with errors w/ more than one line
	then
		print "error" "${resultRaw}"
	else
		result=$(echo "${resultRaw}" | grep "$3")
		if [ "$4" == "-i" ]
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
	#
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
#Arguments are explained in scan()

#Imgur
scan "Imgur" "https://api.imgur.com/3/account/${name}" "${name}" "" "Authorization: Client-ID f7b3d452da6f049" #Imgur Client-ID for UserRecon Reborn
#Reddit                                                                                   
scan "Reddit" "https://api.reddit.com/user/${name}" "${name}"
