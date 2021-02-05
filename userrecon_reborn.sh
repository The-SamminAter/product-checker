#!/bin/bash
RED="\e[1;91m"
GRN="\e[1;92m"
BLU="\e[1;77m" #used to be 0;94
RST="\e[0;0m"

#Title; sorry about the general messiness, I've tried to keep it relatively clean
printf "${RED}\n"
printf "                                                   .-\"\"\"\"-.	\n" #cheap trick to show four quotation marks
printf "                                                  /        \	\n"
printf "${GRN}  _   _               ____                      ${RED} /_        _\	\n"
printf "${GRN} | | | |___  ___ _ __|  _ \ ___  ___ ___  _ __  ${RED}// \      / \\"; echo "\\" #cheap trick to show two back-slashes
printf "${GRN} | | | / __|/ _ \ '__| |_) / _ \/ __/ _ \| '_ \ ${RED}|\__\    /__/|	\n"
printf "${GRN} | |_| \__ \  __/ |  |  _ <  __/ (_| (_) | | | |${RED} \    ||    /	\n"
printf "${GRN}  \___/|___/\___|_|  |_| \_\___|\___\___/|_| |_|${RED}  \        / 	\n"
printf " Reborn ----------------------------------- v0.0   \  __  /		\n"
printf "                                                    '.__.'		\n"
printf "${BLU}"

#Username handling
name=""
if [ "$1" != "" ]
then
	name="$1"
	echo "Using ${name} as the username"
fi
while [ "${name}" == "" ]
do
	read -p "Username: " name
	#Add similar name(s) option
done

#File handling
#Possibly change (fCreate) in the future to allow the use of direct input (think of through something like $2/--fCreate=true)
fCreate=false
fCreateRaw=""
#read -p "Do you want to save the output to a file? " fCreateRaw
if [ "${fCreateRaw}" == "y" ] || [ "${fCreateRaw}" == "Y" ] || [ "${fCreateRaw}" == "Yes" ] || [ "${fCreateRaw}" == "yes" ] #I know, it's crude, but it works
then
	fCreate=true
	#fCount (and fName) are in place to prevent overwriting or adding on to a pre-existing file (if the user chooses to write it)
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
	#$1: URL
	#$2: Name (of site)
	#$3: success text/message
	#$4: failure text/message
	#$5: additional error text/message
	status="If you see this, something is wrong"
	rawResult=$(curl -s "$2")
	cleanedResult=$(grep "${username}" << "${rawResult}")
	echo "${cleanedResult}"
	if [ "${cleanedRresult}" != "" ] #Pretty much, if the result isn't nothing, we presume that it exists
	then
		#printf="${BLU}[${GRN}✓${BLU}] ${GRN}Success: ${BLU}$1 ${GRN}found\n"
		status="success"
	elif [ "${cleanedResult}" == "" ]
	then
		#printf="${BLU}[${RED}X${BLU}] ${RED}Failure: ${BLU}$1 ${RED}not found\n"
		status="failure"
	fi
	echo "${status}"
	print 
	unset status #Unsets the variable, so it doesn't exist until scan() gets called again
}

#print() prints and writes (to fName) information passed to it by scan()
print()
{

}

#Reddit
scan "https://api.reddit.com/users/${username}" "Reddit"

#End of script, reset colors
printf "${RST}"