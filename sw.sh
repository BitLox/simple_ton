#!/bin/bash

cd tonos-cli

folder="SWData"


if [ -d ${folder} ]
then
  function checkbalance {
clear
./GetBalance.sh > SWData/lastbalance.txt
sed -e '/bal/!d' -e 's/bal.*:       //' SWData/lastbalance.txt
}


function  sendtokens {
  clear
  rawaddr=$(cat data/rawaddr.txt)
  phrase=$(cat data/phrase.txt)
  echo "Address of the recipient: "
  read recipientInput
  recipient=$recipientInput
  #LINUX recipient=$(gdialog --title "Data enter" --inputbox "Address of the recipient:" 50 60 2>&1)
  echo "Amount (in TON): "
  read amountInput
  amount=$amountInput
  echo "Purpose: "
  read purposeInput
  purpose=$purposeInput
  trans="./tonos-cli multisig send --addr ${rawaddr} --dest ${recipient} --purpose ${purpose} --sign ${phrase} --value ${amount}"  
  
  # trans="./tonos-cli call ${rawaddr} submitTransaction '{\"dest\":\"${recipient}\",\"value\":${amount},\"bounce\":false,\"allBalance\":false,\"payload\":\"\"}' --abi SafeMultisigWallet.abi.json --sign ${phrase} --purpose ${purpose}"
  echo -n "Do you really want to send ${amount} tokens to address ${recipient} (y/n) "
  # recipient=$(gdialog --title "Data enter" --inputbox "Address of the recipient:" 50 60 2>&1)
  # amount=$(gdialog --title "Data enter" --inputbox "Amount:" 50 60 2>&1)
  # trans="./tonos-cli call ${rawaddr} submitTransaction 
  # '{\"dest\":\"${recipient}\",\"value\":${amount},\"bounce\":false,\"allBalance\":false,\"payload\":\"\"}' 
  # --abi SafeMultisigWallet.abi.json --sign ${phrase}"
  # echo -n "Do you really want to send ${amount} tokens to address ${recipient} (y/n) "
  
  read item
  case "$item" in
      y|Y) echo $trans > trans.tmp.sh
           chmod +x trans.tmp.sh
           ./trans.tmp.sh > SWData/trans.log
           rm trans.tmp.sh
          ;;
      n|N) echo "Operation canceled"
          clear
                  ;;
      *) echo "Enter y or n"
          ;;
  esac
}


function  sendStake {
  clear
  rawaddr=$(cat data/rawaddr.txt)
  phrase=$(cat data/phrase.txt)
  echo "Address of the DePool: "
  read recipientInput
  recipient=$recipientInput
  #LINUX recipient=$(gdialog --title "Data enter" --inputbox "Address of the recipient:" 50 60 2>&1)
  echo "Amount (in TON): "
  read amountInput
  amount=$amountInput
  #LINUX amount=$(gdialog --title "Data enter" --inputbox "Amount:" 50 60 2>&1)
  trans="tonos-cli depool --addr ${recipient} stake ordinary --wallet ${rawaddr} --sign ${phrase} --value ${amount} " 
    
    # trans="./tonos-cli call ${rawaddr} submitTransaction '{\"dest\":\"${recipient}\",\"value\":${amount},\"bounce\":false,\"allBalance\":false,\"payload\":\"\"}' --abi SafeMultisigWallet.abi.json --sign ${phrase} --purpose ${purpose}"

  echo -n "Do you really want to send ${amount} TON Crystal to DePool ${recipient} (y/n) "
  
  read item
  case "$item" in
      y|Y) echo $trans > trans.tmp.sh
           chmod +x trans.tmp.sh
           ./trans.tmp.sh > SWData/trans.log
           rm trans.tmp.sh
          ;;
      n|N) echo "Operation canceled"
          clear
                  ;;
      *) echo "Enter y or n"
          ;;
  esac
}




function checktrans {
clear
rawaddr=$(cat data/rawaddr.txt)
network=$(cat data/network.txt)
tonlive="Your transactions here: https://${network}.ton.live/accounts/accountDetails?id=${rawaddr}"
echo $tonlive
}
#Menu
function menu {
clear
echo
echo -e "\t\t\tSimple Wallet 0.1\n"
echo -e "\t1. Check balance"
echo -e "\t2. Send tokens"
echo -e "\t3. Send stake"
echo -e "\t4. Check transactions"
echo -e "\t0. Exit"
echo -en "\t\tEnter number: "
read -n 1 option
}
#While & Case
while [ $? -ne 1 ]
do
        menu
        case $option in
0)
        break ;;
1)
        checkbalance ;;
2)
        sendtokens ;;
3)
        sendStake ;;       
4)
        checktrans ;;       
*)
        clear
echo "Need to choose";;
esac
echo -en "\n\n\t\t\tPress any key to continue"
read -n 1 line
done
clear

exit
else
  mkdir SWData
  rawaddr=$(cat data/rawaddr.txt)
  balance="./tonos-cli account ${rawaddr}"
  echo $balance > GetBalance.sh
  chmod +x GetBalance.sh
  clear
  cd
  ./sw.sh
fi