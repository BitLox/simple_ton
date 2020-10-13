#!/bin/bash


function step1 {
clear
#Check for folder
folder="tonos-cli"

if [ -d ${folder} ]
then
  echo "folder ${folder} already exist!"
else
  echo "${folder} not exist"
  #Download components and create a folder
  #LINUX wget https://github.com/tonlabs/tonos-cli/releases/download/v0.1.1/tonos-cli_v0.1.1_linux.tar.gz
  wget https://github.com/BitLox/tonos-cli/releases/download/v0.1.17/tonos-cli_v0.1.17_darwin.tar.gz
  mkdir ./tonos-cli
  tar -xvf tonos-cli_v0.1.17_darwin.tar.gz -C ./tonos-cli
  rm tonos-cli_v0.1.17_darwin.tar.gz
  cd ./tonos-cli
  wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.abi.json
  wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.tvc
  #Network configuration
  # ./tonos-cli config --url https://net.ton.dev >> log_step1.txt
  ./tonos-cli config --url https://main.ton.dev >> log_step1.txt
  #Creating a folder for keys
  mkdir ./data
  #Generating seed phrase (3.1.1)
  ./tonos-cli genphrase > data/phrase.txt
  #Sending a response to the log
  cat data/phrase.txt >> log_step1.txt
  #Ydalenie lishnego iz frazu
  sed 's/[^"]*//' data/phrase.txt > data/phrase.tmp.txt
  tr -d '\n' <    data/phrase.tmp.txt > data/phrase.txt 
  rm data/phrase.tmp.txt
  #LINUX sed -i -e 's/[^"]*//' -e '/^$/d' data/phrase.txt
  #Creating a temporary file for generating public key
  phrase=$(cat data/phrase.txt)
  pubkey="./tonos-cli genpubkey ${phrase}"
  echo $pubkey > pubkey.tmp.sh
  #Generating public key (3.1.2)
  chmod +x pubkey.tmp.sh
  ./pubkey.tmp.sh > data/pubkey.txt
  rm pubkey.tmp.sh
  #Sending a response to the log
  cat data/pubkey.txt >> log_step1.txt
  #Removing junk data from public key response
  #LINUX sed -i -e '/Public*/! d' -e 's/P.* //' data/pubkey.txt
  sed '/Public*/! d' data/pubkey.txt > data/pubkey.tmp.txt
  sed 's/P.* //' data/pubkey.tmp.txt > data/pubkey.txt
  #Generating deployment key pair (3.2.1)
  phrase=$(cat data/phrase.txt)
  keypair="./tonos-cli getkeypair deploy.keys.json ${phrase}"
  echo $keypair > keypair.tmp.sh
  chmod +x keypair.tmp.sh
  ./keypair.tmp.sh >> log_step1.txt
  rm keypair.tmp.sh
  #Generating multisignature wallet address (Raw address)
  ./tonos-cli genaddr SafeMultisigWallet.tvc SafeMultisigWallet.abi.json --setkey deploy.keys.json --wc -1 > data/rawaddr.txt
  #Sending a response to the log
  cat data/rawaddr.txt >> log_step1.txt
  #Removing junk data from raw address response
  sed '/Raw*/! d' data/rawaddr.txt > data/rawaddr.tmp.txt
  sed 's/R.* //' data/rawaddr.tmp.txt > data/rawaddr.txt
  #Link to ton.live account
  rawaddr=$(cat data/rawaddr.txt)
  tonlive="https://ton.live/accounts?section=details&id=${rawaddr}"
  #TESTNET tonlive="https://net.ton.live/accounts?section=details&id=${rawaddr}"
  echo $tonlive > account.link.txt
  mkdir to_ton-keys_folder
  cp ./data/rawaddr.txt ./to_ton-keys_folder/hostname.addr
  cp ./deploy.keys.json ./to_ton-keys_folder/msig.keys.json
  mkdir ./SWData
  clear
  echo -e "Succeeded\n\nAll keys: ./data\n\nLogs: ./log_step1.txt\n\nTo check the log:\ncat log_step1.txt\n\nLink to your account (ton.live): ./account.link.txt\n\nGet tokens to your address:\n${rawaddr}\n\nThen Step2"
fi
}
function  checkbalance {
clear
pwd
cd ./tonos-cli
file="GetBalance.sh"
if [ -f ${file} ]
then
./GetBalance.sh > SWData/lastbalance.txt
#LINUX sed -e '/bal/!d' -e 's/bal.*:       //' SWData/lastbalance.txt
sed '/bal/!d' SWData/lastbalance.txt > SWData/lastbalance.tmp.txt
sed 's/bal.*:       //' SWData/lastbalance.tmp.txt > SWData/lastbalance.txt
rm SWData/lastbalance.tmp.txt
cat SWData/lastbalance.txt
cd ..
else
  rawaddr=$(cat data/rawaddr.txt)
  balance="./tonos-cli account ${rawaddr}"
  echo $balance > GetBalance.sh
  chmod +x GetBalance.sh
  clear
  cd ..
  ./wallet.sh
fi
}

function  step2 {
clear
cd ./tonos-cli
#Deploy the multisignature code and data to the blockchain (3.2.4)
pubkey=$(cat data/pubkey.txt)
deploy="./tonos-cli deploy SafeMultisigWallet.tvc '{\"owners\":[\"0x${pubkey}\"],\"reqConfirms\":1}' 
--abi SafeMultisigWallet.abi.json --sign deploy.keys.json --wc -1"
echo $deploy  > deploy.tmp.sh
chmod +x deploy.tmp.sh
./deploy.tmp.sh >> log_step2.txt
rm deploy.tmp.sh
#Querying the status of the multisignature wallet in the blockchain
rawaddr=$(cat data/rawaddr.txt)
status="./tonos-cli account ${rawaddr}"
echo $status > StatCheck.sh
chmod +x StatCheck.sh
./StatCheck.sh >> log_step2.txt
#Creating transaction online (5 tokens to address -1:2e66c896772a6a936d4077ca3472af27bc80bb307b920c8d87b48e6bd066c46d)
phrase=$(cat data/phrase.txt)
trans="./tonos-cli call ${rawaddr} submitTransaction 
'{\"dest\":\"-1:e14aaab96167cbb32709730f86c48f1dd163ad4ff37b9a2e25dcd31550ac7d46\",\"value\":1000000000,\"bounce\":false,\"allBalance\":false,\"payload\":\"\"}' 
--abi SafeMultisigWallet.abi.json --sign ${phrase}"
echo $trans > trans.tmp.sh
chmod +x trans.tmp.sh
./trans.tmp.sh >> log_step2.txt
rm trans.tmp.sh
#Requesting the list of custodian public keys from the blockchain
custocheck="./tonos-cli run ${rawaddr} getCustodians {} --abi SafeMultisigWallet.abi.json"
echo $custocheck > custocheck.tmp.sh
chmod +x custocheck.tmp.sh
./custocheck.tmp.sh >> log_step2.txt
rm custocheck.tmp.sh
clear
echo -e "Succeeded\n\nLogs: ./log_step2.txt\n\nTo check the log:\ncat log_step2.txt"
}
#Menu
function menu {
clear
echo
echo -e "\t\t\tWallet deploying\n"
echo -e "\t1. Step 1"
echo -e "\t2. Check balance"
echo -e "\t3. Step 2"
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
        step1 ;;
2)
        checkbalance ;;
3)
        step2 ;;
*)
        clear
echo "Need to choose";;
esac
echo -en "\n\n\t\t\tPress any key to continue"
read -n 1 line
done
clear

exit