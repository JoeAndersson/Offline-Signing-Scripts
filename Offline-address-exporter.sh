# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x Offline-address-exporter.sh
# Then paste the following command:
# bash Offline-address-exporter.sh

RED='\033[0;31m'	# for red text
NC='\033[0m'	# No Color
enter_quote_to_continue() {	# Only allows the script to continue when they enter '
	echo -e "\nEnter ' to continue."
	read choice
	case "$choice" in 
	\' ) ;;
  	* ) echo -e "Invalid response. Reread instructions";
  	sleep 1
  	enter_quote_to_continue;
	esac
}
enter_ok_to_confirm(){	# Only allows the script to continue when they type ok
	echo -e "\nEnter ok to confirm."
	read choice
	case "$choice" in 
	ok ) ;;
  	* ) echo -e "Invalid response. Reread instructions";
  	sleep 1
  	enter_ok_to_confirm;
	esac
}
check_if_core_is_running() {	# If core is running displays an error message and ends script.
	if [[ $(ps -A | grep "bitcoin-qt" -wc) != 0 ]]  # checks the process status and searches for "bitcoin-qt". Recalls the function recursively until core is closed.
		then
		clear
		echo -e "Bitcoin core is already running. It will now shut down."
		enter_quote_to_continue
		pkill bitcoin-qt
		clear
		echo -e "Continue when Core is fully closed."
		enter_quote_to_continue
		check_if_core_is_running
	else
		break
	fi
}
# Script begins execution here ------------------------------------------------------
clear
echo -e "Offline Address Exporter.\nTo be used offline with an encrypted Bitcoin Core wallet.\nThis script will export your requested addresses allowing you to create psbts.\nMove this window to the right side of your screen."
enter_quote_to_continue
clear
echo -e "Bitcoin core will open, then return back to this window."
enter_quote_to_continue	# Wait for any key press from user.
check_if_core_is_running
# Launches bitcoin-qt from a second terminal window, local server necessary to accept RPC calls. Only the local machine has access, more info here https://en.bitcoin.it/wiki/API_reference_(JSON-RPC)
gnome-terminal -- ./bitcoin-qt -server	
clear
echo -e "Let Bitcoin Core finish loading,\nAll wallets will be unloaded."
enter_quote_to_continue
#numLines=$(./bitcoin-cli listwallets | wc -l)	# Counts the number of lines in the listed wallets.
let numWalletsLoaded=$(./bitcoin-cli listwallets | wc -l)-2	# The number of wallets loaded is the number of lines - 2.
for ((i = 1; i <= $numWalletsLoaded; i++)) do	# Loops through the number of wallets loaded and unloads each one.
	loadedWallet=$(./bitcoin-cli listwallets | sed '2q;d' | cut -d '"' --fields 2)
	./bitcoin-cli unloadwallet "$loadedWallet"
	done
clear
echo -e "Load only your encrypted wallet in Bitcoin Core"
enter_ok_to_confirm
walletName=$(./bitcoin-cli listwallets | sed '2q;d' | cut -d '"' --fields 2)	# Sets walletName to the loaded wallet. Only one wallet should be loaded.

if [ $(./bitcoin-cli listwallets | wc -l) != 3 ]	# Checks if no wallet or multiple wallets are loaded and exits script with error message.
	then
	clear
	echo -e "Cannot find wallet. Follow the instructions carefully. Only one wallet should be loaded. Rerun script." 
	exit
fi
watchWalletName="Watch-only wallet of $walletName"
./bitcoin-cli loadwallet "$watchWalletName"
if [[ $(./bitcoin-cli listwallets | grep "$watchWalletName" -wc) != 0 ]]	#  If a watch only wallet already exists returns error and exits script.
	then
	clear
	echo -e "Warning, a watch only wallet for $walletName has been detected. It must be deleted before continuing.\nCore will first close."
	enter_quote_to_continue
	pkill bitcoin-qt
	clear
	echo -e "Let Core fully shut down."
	enter_quote_to_continue
	clear
	echo -e "${RED}$watchWalletName will be deleted from the hard drive.${NC}"
	enter_ok_to_confirm
	rm -r ~/.bitcoin/wallets/"$watchWalletName"
	rm -r ~/Documents/"$watchWalletName"
	sed -i '/, "$watchWalletName"/d' ~/.bitcoin/settings.json	# deletes the wallet name from the settings.json so it doesn't have the wallet skipping error on loadup.
	clear
	echo -e "$watchWalletName deleted from default .bitcoin path. If the default .bitcoin path has been changed then it has not been deleted and you must do so manually.\nRerun script."
	exit
else
	break
fi
clear
echo -e "Your wallet's name is '$walletName'\n\n${RED}You will need a change address if you are not spending the whole UTXO.${NC} \nYou can request another receiving address now and label it change address with today's date and the amount to be sent to it. \nWhen you rescan the blockchain on your node, you will know which one is the change address because it will be empty assuming you are only importing loaded address(es) to spend.\nAddress labels will not be transferred to the watch only wallet."
enter_ok_to_confirm

adrArray=()	# Empty array that will later contain all the addresses on the encrypted wallet. 
addressesChosenArr=()
adrRegex='^[1,3,bc1q]'		# Regular expression, matches a string that begins with 1, 3 or bc1q.	
j=3
x=8

while [[ $(./bitcoin-cli -rpcwallet="$walletName" listreceivedbyaddress 0 true | sed ''$j'q;d' | cut -d '"' --fields 4) =~ $adrRegex ]]; do	# Appends all the listed addresses on the encrypted wallet to the adrArray.
	str=$(./bitcoin-cli -rpcwallet="$walletName" listreceivedbyaddress 0 true | sed -n ''$j','$x'p')
	adrArray+=("$str")
	let j+=8
	let x+=8
done
listAvailableAddresses() {					# Function that lists all the addresses sequentially.
	n=1
	for address in "${adrArray[@]}"
	do
    		echo -e "$n.$address"
     		let n++
	done
	let n--
}
listSelectedAddresses() {			# Function that lists only the selected addresses.
	for address in "${addressesChosenArr[@]}"
	do
    		echo -e "Address Selected:" $address
    		echo -e ""
	done
}
clear
echo -e "Maximize this window. You may need to scroll up when the addresses appear.\nIf you have never synced this wallet with a node then all addresses will show a balance of 0. This is expected."
enter_quote_to_continue
askAddressesToImport() {			# Function to ask user what address to import
	clear
	listAvailableAddresses
	echo -e "--------------------------------------------------------------------"
	listSelectedAddresses
	echo -e "\nEnter (1-$n) to add an address. \nWhen you have finished selecting addresses type import"
	read numChosen
	if [[ $numChosen = *import* ]]	
		then
		echo -e ""
	elif [[ $numChosen -gt $n || $numChosen = "" || $numChosen = 0* || $numChosen =~ [^0-9,^:space] ]] 
		then
		clear
		echo -e "Invalid choice.\nSelect one address at a time, you will be given the opportunity to add more after. \nType the number left of the address not the address."
		enter_quote_to_continue
		clear
		askAddressesToImport	# recursive function, starts over if user selects invalid option
	else
		clear
			if [[ ${adrArray[$numChosen-1]} != "" ]]	# checks if it's not an empty string. It would be an empty string if the user already selected the number.
				then
				addressesChosenArr+=("${adrArray[$numChosen-1]}")
				adrArray[$numChosen-1]=""	# sets the selected address to an empty string
				clear
				askAddressesToImport
			else 
				clear
				echo -e "Address already added."
				enter_quote_to_continue
				askAddressesToImport
			fi
	fi
}
./bitcoin-cli createwallet "$watchWalletName" true true	# creates the watch only wallet 
./bitcoin-cli loadwallet "$walletName"
./bitcoin-cli loadwallet "$watchWalletName"	# loads watch only wallet, necessary if rerunning the script
clear
askAddressesToImport

for detailedAddress in "${addressesChosenArr[@]}" 
do
address=$(echo $detailedAddress | grep --max-count 1 '"address": "' | cut -d '"' --fields 4)	# sets address = to the first grep match of "address:": " which should always be in the beginning.
echo $address
	if [[ $address == bc1q* ]]
		then
		pubKey=$(./bitcoin-cli -rpcwallet="$walletName" getaddressinfo $address | grep --max-count 1 '"pubkey": "' | cut -d '"' --fields 4)
    		desc=$(./bitcoin-cli getdescriptorinfo "wpkh($pubKey)" | sed '2q;d' | cut -d '"' --fields 4)
		./bitcoin-cli -rpcwallet="$watchWalletName" importmulti '[{"desc" : "'$desc'","timestamp" : "now","label" : "", "watchonly": true}]' '{ "rescan": false}'
	elif [[ $address == 3* ]]
		then
		pubKey=$(./bitcoin-cli -rpcwallet="$walletName" getaddressinfo $address | grep --max-count 1 '"pubkey": "' | cut -d '"' --fields 4)
		desc=$(./bitcoin-cli getdescriptorinfo "sh(wpkh($pubKey))" | grep --max-count 1 '"descriptor": "sh(wpkh(' | cut -d '"' --fields 4)
		./bitcoin-cli -rpcwallet="$watchWalletName" importmulti '[{"desc" : "'$desc'","timestamp" : "now","label" : "", "watchonly": true}]' '{ "rescan": false}'
	elif [[ $address == 1* ]]
		then
		pubKey=$(./bitcoin-cli -rpcwallet="$walletName" getaddressinfo $address | grep --max-count 1 '"pubkey": "' | cut -d '"' --fields 4)
		desc=$(./bitcoin-cli getdescriptorinfo "pkh($pubKey)" | grep --max-count 1 '"descriptor": "pkh(' | cut -d '"' --fields 4)
		./bitcoin-cli -rpcwallet="$watchWalletName" importmulti '[{"desc" : "'$desc'","timestamp" : "now","label" : "", "watchonly": true}]' '{ "rescan": false}'
	else 
		echo -e "Address type not recognized-cannot import this address"
	fi
done
echo -e "Imported Successfully."
enter_quote_to_continue
clear
echo -e "Core will now close. When the file window pops up, copy the folder titled "$watchWalletName" onto a wiped USB drive then return to this window.\nYou can minimize any Nautilus-Share-Message terminals if you see them."
enter_quote_to_continue
mkdir -p ~/Documents/"$watchWalletName"	# Makes a directory in ~/Documents that will contain the watch wallet.dat
./bitcoin-cli -rpcwallet="$watchWalletName" backupwallet ~/Documents/"$watchWalletName"/wallet.dat
pkill bitcoin-qt	# Safely closes bitcoin-qt.
clear
pkill nautilus	# closes nautilus so theres only one window
gnome-terminal -- nautilus ~/Documents
echo -e "Confirm that you have copied the folder '$watchWalletName' to your USB drive. \n${RED}$watchWalletName will be deleted from the hard drive.${NC}"
enter_ok_to_confirm
rm -r ~/.bitcoin/wallets/"$watchWalletName"
rm -r ~/Documents/"$watchWalletName"
clear
echo -e "$watchWalletName deleted"
echo -e "\nTransfer this USB drive to your node and run the restore script Node-address-importer.sh\nIf you know the blockheight of your earliest transaction then you can save a lot of time during the rescan. You can estimate it from the date of the address."
