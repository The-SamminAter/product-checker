#!/bin/bash
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
	#$2: site name/error message (if $1 is "notice")
	#$3: URL to open when the notification is pressed
	if [ "$1" == "success" ]
	then
		tput bel
		printf "${BLU}[${GRN}\xE2\x9C\x94${BLU}] ${GRN}$2 is in stock\n"
		shouldOpenURL=$(osascript -e 'tell app "System Events" to display dialog "'"$2 is in stock! Click OK to view it."'" with title "Product check"' 2>&1)
		if [ "${shouldOpenURL}" == "button returned:OK" ]
		then
			open "$3" #This opens the product's URL in the user's default browser, if they hit the 'OK' button
		fi
	elif [ "$1" == "failure" ]
	then
		printf "${BLU}[${RED}X${BLU}] ${RED}$2 is out of stock\n"
	elif [ "$1" == "notice" ]
	then
		printf "${BLU}[${YLW}!${BLU}] ${YLW}Notice: $2\n"
	fi
}


#URL checking:
#Arguments are explained in scan()
infiniteLoop=true
while [ ${infiniteLoop} == true ]
do
	print "notice" "check started"
	scan "ASUS DUAL GeForce RTX 3060 OC Edition" "https://www.canadacomputers.com/product_info.php?cPath=43_557_559&item_id=190839" 'itemprop="availability" content="InStock"'
	scan "ASUS DUAL GeForce RTX 3060 Ti OC Edition" "https://www.canadacomputers.com/product_info.php?cPath=43_557_559&item_id=184760" 'itemprop="availability" content="InStock"'
	scan "ASUS DUAL GeForce RTX 3060 Ti OC Edition" "https://www.memoryexpress.com/Products/MX00114818" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ASUS DUAL GeForce RTX 3070" "https://www.newegg.ca/asus-geforce-rtx-3070-dual-rtx3070-8g/p/N82E16814126460" '"Instock":true'
	scan "ASUS DUAL GeForce RTX 3070 OC Edition" "https://www.memoryexpress.com/Products/MX00114566" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ASUS KO GeForce RTX 3060 Ti OC Edition" "https://www.memoryexpress.com/Products/MX00114888" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ASUS KO GeForce RTX 3070 OC Edition" "https://www.memoryexpress.com/Products/MX00114785" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "EVGA GeForce RTX 3060 XC" "https://www.newegg.ca/evga-geforce-rtx-3060-12g-p5-3655-kr/p/N82E16814487538" '"Instock":true'
	scan "EVGA GeForce RTX 3060 XC" "https://www.newegg.ca/evga-geforce-rtx-3060-12g-p5-3657-kr/p/N82E16814487539" '"Instock":true'
	scan "EVGA GeForce RTX 3060 XC" "https://www.memoryexpress.com/Products/MX00116013" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "EVGA GeForce RTX 3060 Ti XC" "https://www.memoryexpress.com/Products/MX00115014" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "GIGABYTE GeForce RTX 3060" "https://www.newegg.ca/gigabyte-geforce-rtx-3060-gv-n3060eagle-12gd/p/N82E16814932399" '"Instock":true'
	scan "GIGABYTE GeForce RTX 3060 EAGLE OC Edition" "https://www.canadacomputers.com/product_info.php?cPath=43_557_559&item_id=189626" 'itemprop="availability" content="InStock"'
	scan "GIGABYTE GeForce RTX 3060 EAGLE OC Edition" "https://www.memoryexpress.com/Products/MX00116063" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "GIGABYTE GeForce RTX 3060 Ti" "https://www.newegg.ca/gigabyte-geforce-rtx-3060-ti-gv-n306teagle-8gd/p/N82E16814932379" '"Instock":true'
	scan "GIGABYTE GeForce RTX 3060 Ti EAGLE" "https://www.memoryexpress.com/Products/MX00114927" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "GIGABYTE GeForce RTX 3060 Ti EAGLE OC Edition" "https://www.memoryexpress.com/Products/MX00114926" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ZOTAC GAMING GeForce RTX 3060" "https://www.newegg.ca/zotac-geforce-rtx-3060-zt-a30600e-10m/p/N82E16814500509" '"Instock":true'
	scan "ZOTAC GAMING GeForce RTX 3060" "https://www.memoryexpress.com/Products/MX00116162" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ZOTAC GAMING GeForce RTX 3060 OC" "https://www.memoryexpress.com/Products/MX00116159" "<header>Availability:" "-li" "2" "Out of Stock"
	scan "ZOTAC GAMING GeForce RTX 3070" "https://www.newegg.ca/zotac-geforce-rtx-3070-zt-a30700h-10p/p/N82E16814500505" '"Instock":true'
	#scan "test1" "https://www.newegg.ca/seagate-ironwolf-st6000vn0033-6tb/p/N82E16822172057" '"Instock":true'
	#scan "test2" "https://www.canadacomputers.com/product_info.php?cPath=710_1925_1912_1911&item_id=187347" 'itemprop="availability" content="InStock"'
	#scan "test3" "https://www.memoryexpress.com/Products/MX00115275" "<header>Availability:" "-li" "2" "Out of Stock"
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
	sleep ${delay} #Yeah yeah I know that the scans take time, but exact precision isn't neccesary
done
