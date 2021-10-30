#!/usr/bin/env bash
#A script made for a friend of mine, to check if any of the graphics cards he's looking to buy are finally in stock
#Most of this code is originally from userrecon_reborn

#Coloring:
RST="\e[0;0m"
RED="\e[1;91m"
GRN="\e[1;92m" #1;32 or 1;92
BLU="\e[1;96m" #What's supposed to be blue looks purple so cyan (1;36 or 1;96) is used
YLW="\e[1;93m" #1;33 or 1;93
#If the user or the script exits (while not being ran in silent mode), this clears the colors
exitRST()
{
	printf "${RST}"
	printf ""
	exit
}
trap "exitRST" EXIT 


#Handles one (1) argument, which it uses as the time delay (in the infinite loop)
if [ "$1" ]
then
	delay=$(printf %.0f "$1") #Rounds $1's to a whole number
else
	delay="300"
fi

#scan() scans URLs based on info passed to it, determines if the profile exists or not, and then passes that on to print()
scan()
{
	#$1: name (of product)
	#$2: URL - can include the headers
	#$3: string to grep for (as an indication of success), unless $4 is set to -l, in which case is (part of) the target line
	#$4: if set to -l (as in line), gets the line number that $3 is on, and adds $5 to it - can also be used with -i (would look like '-li')
	#	 if set to -i (as in inverse), turns $3 (or in the case of -l, $5) into an indication of failure - only use if necessary (because is more prone to false-negatives)
	#$5: used if $4 is set to -l or -li - adds its value to the line number that $3 is on
	#$6: used if $4 is set to -l or -li - string to grep for (as an indication of success) - is affected by -i
	if [ "$4" == "-l" ] || [ "$4" == "-li" ]
	then
		curl -s $2 >> ".tmp" #The $2 isn't in quotation marks to enable the use of headers
		lineNum=$(sed -n "/$3/=" ".tmp")
		lineNumNew=$(echo "${lineNum} + $5" | bc)
		result=$(sed -n "${lineNumNew}p" ".tmp" | grep "$6")
		rm ".tmp"
	else
		result=$(curl -s "$2" | grep "$3")
	fi
	if [ "$4" == "-i" ] || [ "$4" == "-li" ]
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
	print "${status}" "$1" "$2"
	unset status
}


#print() prints information passed to it by scan()
print()
{
	#$1: status message
	#$2: product name or notice message (if $1 is "notice")
	#$3: URL to open (if chosen)
	if [ "$1" == "success" ]
	then
		printf "${BLU}[${GRN}\xE2\x9C\x94${BLU}] ${GRN}$2 is in stock\n"
		tput bel #I believe this works on all OSes
		if [ "$(uname)" == "Darwin" ] #This is done presuming that we have automation permission (if necessary)
		then
			shouldOpenURL=$(osascript -e 'tell app "System Events" to display dialog "'"$2 is in stock! Click OK to view it."'" with title "Product check"' 2>&1)
			if [ "${shouldOpenURL}" == "button returned:OK" ]
			then
				open "$3" #This opens the product's URL in the user's default browser, if they hit the 'OK' button
			fi
		else #Presume that the OS is linux
			zenity --question \
			--title "Product check" \
			--text "$2 is in stock! Would you like to view it?"	
			if [ $? = 0 ]
			then
				sensible-browser "$3" #This opens the product's URL in the user's default browser, if they hit the 'Yes' button
			fi
		fi
	elif [ "$1" == "failure" ]
	then
		printf "${BLU}[${RED}X${BLU}] ${RED}$2 is out of stock\n"
	elif [ "$1" == "notice" ]
	then
		printf "${BLU}[${YLW}!${BLU}] ${YLW}Notice: $2\n"
	fi
}


#Automation permission checking (required for Mojave/10.14 and up)
if [ "$(uname)" == "Darwin" ]
then
	case $(sw_vers -productVersion) in
		10.14*|10.15*|10.16*|11*|10.17*|12*)
			#Error message from when we don't have perms (from some 10.15.x):
			#28:42: execution error: Not authorized to send Apple events to System Events. (-1743)
			#Error message from when we do have perms (from 10.12.6):
			#28:42: execution error: System Events got an error: Can’t make application "System Events" into type string. (-1700)
			print "notice" "Automation permission requested for Terminal"
			automationTest=$(osascript -e 'tell app "System Events" to display dialog' 2>&1 | awk {'print $NF'})
			if [ "${automationTest}" == "(-1743)" ]
			then
				print "notice" "Automation permission is required to show alerts"
				print "notice" "Please grant Terminal the permissions in 'System Preferences'->'Security & Privacy'->'Privacy'->'Automation'"
			elif [ "${automationTest}" == "(-1700)" ]
			then
				: #This is the desired result
			else
				print "notice" "Unknown error message: ${automationTest}"
			fi
			#Getting the focused window so we can return to it immediately (need to check if it requires perms):
			lastWindow=$(osascript -e 'tell application "System Events" to get name of application processes whose frontmost is true and visible is true')
			osascript -e "tell application \"${lastWindow}\" to activate"
	esac
else #Presume that the OS is Linux
	if [[ -z "$(command -v zenity)" ]] #Source: http://stackoverflow.com/questions/592620/
	then
		print "notice" "Zenity doesn't appear to be installed. Please install Zenity to use this script"
	fi
fi


#URL checking:
#Arguments are explained in scan()
while [ true ]
do	
	print "notice" "check started"
	#scan "test1" "https://www.newegg.ca/seagate-ironwolf-st6000vn0033-6tb/p/N82E16822172057" '"Instock":true'
	#scan "test2" "https://www.canadacomputers.com/product_info.php?cPath=710_1925_1912_1911&item_id=187347" 'itemprop="availability" content="InStock"'
	#scan "test3" "https://www.memoryexpress.com/Products/MX00115275" "<header>Availability:" "-li" "2" "Out of Stock"
	#scan "test4" "https://orders.maximumsettings.com/" "Hardware capacity has been reached. Awaiting new gaming servers." "-i"
	if [ ${delay} == 1 ]
	then
		print "notice" "check completed - 1 second until the next one"
	elif [[ ${delay} -lt 60 ]]
	then
		print "notice" "check completed - ${delay} seconds until the next one"
	elif [ ${delay} == 60 ]
	then
		print "notice" "check completed - 1 minute until the next one"
	else
		print "notice" "check completed - "$(printf %.2f $(echo "${delay}/60" | bc -l))" minutes until the next one" #Prints the calculation (of minutes) with rounding to two decimal places
	fi
	sleep ${delay}
done
