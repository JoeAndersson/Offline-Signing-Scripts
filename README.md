# Core Offline Signing Scripts
These scripts allow you to create unsigned transactions from an offline Bitcoin Core wallet.

You can use a bitcoin core wallet in the standard cold storage signing procedure. Create psbt online -> transfer psbt to offline wallet and sign -> transfer psbt online and broadcast.

They require no dependencies outside of Bitcoin Core and use only standard GNU commands; they can be run fully offline.

The scripts cannot touch your private keys as they never require decrypting the wallet.

Optimized for code review and auditability.

Import only the addresses you need for maximum privacy; no leaking xpubs.

How to Setup The Scripts:

It is designed to work with Ubuntu and the default .bitcoin location (~/.bitcoin).
For change addresses you will need to specify another receiving address.
Compatible with standard Bitcoin Core wallets and descriptor wallets.
Always keep good labels of all your transaction data on the offline wallet.
You will need a synced node.
If you will have multiple empty addresses then you will need to make note of which one is for each transaction. Such a scenario may be when you are making more than one transaction with change or when making a transaction and also confirming an incoming transaction.

How to Start the Scripts:

Download both .sh scripts

Put Node-address-importer.sh in your bitcoin-0.21.x/bin folder on your online computer.

Put Offline-address-exporter.sh in your bitcoin-0.21.x/bin folder on your offline computer.

---Offline:

Right-click in folder, 

Select "Open in Terminal"

Open a new Terminal

Enter "bash Offline-address-exporter.sh" and follow instructions on screen.

---Node:

Transfer USB with watch only wallet to your node

Right-click in folder, 

Select "Open in Terminal"

Open a new Terminal

Enter "bash Node-address-importer.sh" and follow instructions on screen to create unsigned transaction.

End of script. Only core from here on

---Offline:

Transfer USB with psbt to offline wallet

Decrypt wallet in the console with walletpassphrase "passphrase" 60 

Select File -> Load PSBT from file...

Confirm amount, addresses, and fee of the transaction

Sign psbt and transfer to USB

---Online:

Load psbt from USB

Select File -> Load PSBT from file...

Confirm details one last time

Broadcast if all is correct

Check for confirmations

----------------------------------------------------------------------------------------------------------------------------------------------------
This work is built on the work of Ben Westgate https://github.com/BenWestgate/yeti.Bash, JW Weatherman  Will Weatherman, Robert Spigler (the Yeticold Developers) https://github.com/JWWeatherman/yeticold and the Bitcoin Developers https://github.com/bitcoin/bitcoin  
