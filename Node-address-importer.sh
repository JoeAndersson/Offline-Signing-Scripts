# Click Files on the Left hand bar, Navigate to home/bitcoin/bin/
# Move this file into the home/bitcoin/bin/ folder
# Right click in the /bin/ folder once more and select "open in terminal" and paste the following command:
# chmod +x Node-address-importer.sh
# Then paste the following command:
# bash Node-address-importer.sh

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
		echo -e "When Core is fully closed you may continue."
		enter_quote_to_continue
		check_if_core_is_running
	else
		break
	fi
}
RED='\033[0;31m'	# for red text
NC='\033[0m'	# No Color
# Script begins execution here -----------------------------------------------------
clear
echo -e "Online Address Importer. \nThis script will load your watch only wallet onto your node to create psbts and watch your transactions confirm. \nMove this window to the right side of your screen. \nCore will close if it is open."
enter_quote_to_continue
pkill bitcoin-qt
clear
echo -e "Read the instructions first then press enter ' to begin.\n\nInsert your USB drive with your watch only wallet.\nA file window will open. Click your USB drive on the left hand side, then right click your watch only wallet and select copy. \nOnce copied return to this script.\nYou can minimize any Nautilus-Share-Message terminals if you see them."
enter_quote_to_continue
pkill nautilus
gnome-terminal -- nautilus
clear
echo -e "Once copied, paste the watch only wallet into the next file window that opens."
enter_quote_to_continue
pkill nautilus
gnome-terminal -- nautilus ~/.bitcoin/wallets
clear
echo -e "Confirm your watch only wallet is in the .bitcoin/wallets folder."
enter_ok_to_confirm
clear
echo -e "Bitcoin Core will open."
enter_quote_to_continue
check_if_core_is_running
gnome-terminal -- ./bitcoin-qt -server
clear
echo -e "Let Bitcoin Core finish loading\nAll wallets will be unloaded."
enter_quote_to_continue
let numWalletsLoaded=$(./bitcoin-cli listwallets | wc -l)-2	# The number of wallets loaded is the number of lines - 2.
for ((i = 1; i <= $numWalletsLoaded; i++)) do	# Loops through the number of wallets loaded and unloads each one.
	loadedWallet=$(./bitcoin-cli listwallets | sed '2q;d' | cut -d '"' --fields 2)
	./bitcoin-cli unloadwallet "$loadedWallet"
	done
clear
echo -e "Load only your watch only wallet in Bitcoin Core"
enter_ok_to_confirm
watchWalletName=$(./bitcoin-cli listwallets | sed '2q;d' | cut -d '"' --fields 2)	# Sets walletName to the loaded wallet. Only one wallet should be loaded.

if [ $(./bitcoin-cli listwallets | wc -l) != 3 ]	# Checks if no wallet or multiple wallets are loaded and exits script with error message.
	then
	clear
	echo -e "Cannot find wallet. Follow the instructions carefully. Only one wallet should be loaded. Rerun script." 
	exit
fi
clear
echo -e "Your watch only wallet is named '$watchWalletName'.\n\nEnter the blockheight of the oldest address you would like to import. If you do not know it, enter 0\n It can take many hours to rescan from the beginning of the blockchain."
read -p "Blockheight = " blockHeight 
clear
echo -e "Rescanning blockchain from block $blockHeight. It can take hours."
./bitcoin-cli -rpcwallet="$watchWalletName" rescanblockchain $blockHeight
echo -e "Rescan complete. Wallet is ready to create transactions.\nInstructions for sending below.\n"
# coin control instructions
echo -e "To enable Coin Control, go to Settings->Options->Wallet->'Enable coin control features'. Now in the Send window, you can click 'Inputs...' to select which UTXO you want to use."
# change address instructions
echo -e "\nIf you are not spending the entire UTXO then you will need to specify a change address. Check the custom change address box and enter your change address. If you forgot to import a change address then you can simply copy over a new address name from your encrypted wallet. Your balance will not be updated on the node but you can be sure that the address has been funded once the transaction confirms."

# be more specific here
echo -e "\nIf you are watching an address to confirm an incoming transaction 3 confirmations is recommended for large amounts of money. For very large amounts of money 6 is recommmended."

echo -e '\nWhen you are ready to finalize the transaction click Create Unsigned and save the transaction to the USB drive. To find the USB drive click Computer -> "/" -> media -> "your username" -> double-click the folder . You can change the transaction name to unsigned.psbt'

echo -e '\nTransfer the unsigned transaction to your offline computer. You must unlock your wallet before signing the transaction. To unlock the wallet load it then press CTRL+T -- If you have multiple wallets loaded then select the correct one in the top left. \nType walletpassphrase "your_passphrase" 90   (whatever amount of time (in seconds) is appropriate for you to sign the transaction, you can close core when finished to encrypt it back)\nNow insert your USB stick and click File -> Load PSBT from file. \nTo find the USB drive click Computer -> "/" -> media -> "your username" -> double-click the folder. Select the .psbt and load. \n\n'${RED}'CONFIRM THE ADDRESSES AND AMOUNTS ARE CORRECT'${NC}'.\nIf all is correct then sign the transaction and save it to the USB as you did before. Title it signed.psbt \nTransfer the USB stick to the online computer. Load the psbt, confirm the details again and click broadcast. Wipe the USB drive.'

echo -e "You can wait if you want to verify the transaction gets confirmed."

echo -e "\n\n\nCore will close now and delete your watch wallet from this computer.\nContinue after saving the psbt to the USB."
enter_ok_to_confirm
pkill bitcoin-qt
echo -e "Wait until Core is fully closed"
enter_quote_to_continue
echo -e "Confirm deleting '$watchWalletName' from this computer."
enter_ok_to_confirm
rm -r ~/.bitcoin/wallets/"$watchWalletName"
echo -e "'$watchWalletName' deleted from .bitcoin/wallets\nScript Complete, sign psbt offline then return online and broadcast. Wipe USB drive afterwards. Scroll up for spending instructions. No psbts should be saved to the online node."
