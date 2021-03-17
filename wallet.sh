#!/bin/bash

case "$OSTYPE" in
  solaris*) os_type="SOLARIS" ;; 
  darwin*)  os_type="OSX" ;; 
  linux*)   os_type="LINUX" ;; 
  bsd*)     os_type="BSD" ;; 
  msys*)    os_type="WINDOWS" ;; 
  *)        os_type="unknown" ;; 
esac

function step1 {
clear
#Check for folder
# folder="tonos-cli"
# 
# if [ -d ${folder} ]
# then
#   echo "Folder ${folder} already exists!"
# else
  echo "${folder} does not exist, fetching"
  echo
  #Download components and create a folder

  if [ "$os_type" == 'LINUX' ] 
  then
    wget http://sdkbinaries.tonlabs.io/tonos-cli-0_6_0-linux.zip
    unzip tonos-cli-0_6_0-linux.zip 
    rm tonos-cli-0_6_0-linux.zip
  fi
  if [ "$os_type" == 'OSX' ]
  then
    wget http://localhost/tonos-cli-0_6_0-darwin.zip
    # wget http://sdkbinaries.tonlabs.io/tonos-cli-0_6_0-darwin.zip
    unzip tonos-cli-0_6_0-darwin.zip 
    rm tonos-cli-0_6_0-darwin.zip
  fi

  wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.abi.json
  wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.tvc
  wget https://raw.githubusercontent.com/FreeTON-Network/fld.ton.dev/main/scripts/Marvin.abi.json
  
#Creating a folder for keys
mkdir data

networkMenu
read -p "" optionNet
case $optionNet in
  1)
    setMain 
    ;;
  2)
    setDev 
    ;;
  3)
    setFLD 
    ;;
esac
clear

wcMenu
read -p "" optionWC
case $optionWC in
  1)
    setZero 
    ;;
  2)
    setMinusOne 
    ;;
esac
clear

phraseMenu
read -p "" optionPhrase
case $optionPhrase in
  1)
    setGenPhrase 
    ;;
  2)
    setCustomPhrase 
    ;;
esac
clear
  
./tonos-cli config --url https://$url >> log_step1.txt
./tonos-cli config --wc $workchain >> log_step1.txt
  
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
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -i -e '/Public*/! d' -e 's/P.* //' data/pubkey.txt
  fi
  if [ "$os_type" == 'OSX' ]
  then
    sed '/Public*/! d' data/pubkey.txt > data/pubkey.tmp.txt
    sed 's/P.* //' data/pubkey.tmp.txt > data/pubkey.txt
    rm data/pubkey.tmp.txt
  fi

  #Generating deployment key pair (3.2.1)
  phrase=$(cat data/phrase.txt)
  keypair="./tonos-cli getkeypair deploy.keys.json ${phrase}"
  echo $keypair > keypair.tmp.sh
  chmod +x keypair.tmp.sh
  ./keypair.tmp.sh >> log_step1.txt
  rm keypair.tmp.sh
  #Generating multisignature wallet address (Raw address)
  ./tonos-cli genaddr SafeMultisigWallet.tvc SafeMultisigWallet.abi.json --setkey deploy.keys.json --wc $workchain > data/rawaddr.txt
  #Sending a response to the log
  cat data/rawaddr.txt >> log_step1.txt
  #Removing junk data from raw address response
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -i -e '/Raw*/! d' -e 's/R.* //' data/rawaddr.txt
  fi
  if [ "$os_type" == 'OSX' ]
  then
    sed '/Raw*/! d' data/rawaddr.txt > data/rawaddr.tmp.txt
    sed 's/R.* //' data/rawaddr.tmp.txt > data/rawaddr.txt
    rm data/rawaddr.tmp.txt
  fi
  
  #Link to ton.live account
  rawaddr=$(cat data/rawaddr.txt)
  tonlive="https://${network}.ton.live/accounts/accountDetails?id=${rawaddr}"
  echo $tonlive > account.link.txt
  mkdir to_ton-keys_folder
  cp ./data/rawaddr.txt ./to_ton-keys_folder/hostname.addr
  cp ./deploy.keys.json ./to_ton-keys_folder/msig.keys.json
  mkdir ./SWData
  cd ..
  clear
  echo -e "Succeeded\n\nAll keys: ./data\n\nLogs: ./log_step1.txt\n\nTo check the log:\ncat log_step1.txt\n\nLink to your account (${network}.ton.live): ./account.link.txt\n\nSend some tokens to your address:\n${rawaddr}\n\nThen Step2.sh"
# fi
}

function  checkbalance {
clear
cd ./tonos-cli
file="GetBalance.sh"

if [ -f ${file} ]
then
  ./GetBalance.sh > SWData/lastbalance.txt
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -e '/bal/!d' -e 's/bal.*:       //' SWData/lastbalance.txt
    cd ..
  fi
  if [ "$os_type" == 'OSX' ]
    then
    sed '/bal/!d' SWData/lastbalance.txt > SWData/lastbalance.tmp.txt
    sed 's/bal.*:       //' SWData/lastbalance.tmp.txt > SWData/lastbalance.txt
    rm SWData/lastbalance.tmp.txt
    cat SWData/lastbalance.txt
    cd ..
  fi
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

function  showaddress {
  clear
  cd ./tonos-cli
  cat data/rawaddr.txt 
  cd ..
}

function setGenPhrase {
#Generating seed phrase (3.1.1)
./tonos-cli genphrase > data/phrase.txt
#Sending a response to the log
cat data/phrase.txt >> log_step1.txt
#Ydalenie lishnego iz frazu
if [ "$os_type" == 'LINUX' ] 
then
  sed -i -e 's/[^"]*//' -e '/^$/d' data/phrase.txt
fi
if [ "$os_type" == 'OSX' ]
then
sed 's/[^"]*//' data/phrase.txt > data/phrase.tmp.txt
  tr -d '\n' <    data/phrase.tmp.txt > data/phrase.txt 
  rm data/phrase.tmp.txt
fi
break;
}

function setCustomPhrase {
  echo
echo -e "\tSecret phrase:"  
  read inputPhrase
  customPhrase=$inputPhrase
  echo $inputPhrase > data/phrase.txt
  cat data/phrase.txt >> log_step1.txt
  break;
}

function setMain {
  network="MAIN";
  url="MAIN.TON.DEV";
  echo "MAIN.TON.DEV" > data/url.txt
  echo "MAIN" > data/network.txt
  # break;
}

function setDev {
  network="NET";
  url="NET.TON.DEV";
  echo "NET.TON.DEV" > data/url.txt
  echo "NET" > data/network.txt
  # break;
}

function setFLD {
  network="FLD";
  url="gql.custler.net";
  echo "gql.custler.net" > data/URL.txt
  echo "FLD" > data/network.txt
  # break;
}

function setZero {
  workchain="0";
  break;
}

function setMinusOne {
  workchain="-1";
  break;
}

function  step2 {
  
  # NEED TO CHECK IF STEP 1 WAS DONE
  
clear
cd ./tonos-cli
#Deploy the multisignature code and data to the blockchain (3.2.4)
pubkey=$(cat data/pubkey.txt)
deploy="./tonos-cli deploy SafeMultisigWallet.tvc '{\"owners\":[\"0x${pubkey}\"],\"reqConfirms\":1}' 
--abi SafeMultisigWallet.abi.json --sign deploy.keys.json "
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

#Creating transaction online (5 tokens to address 0:2fa8e77ea0855ce446bd60e22035a48d484f55fc05e669661f16f8fb063beacb)
# phrase=$(cat data/phrase.txt)
# trans="./tonos-cli call ${rawaddr} submitTransaction '{\"dest\":\"0:2fa8e77ea0855ce446bd60e22035a48d484f55fc05e669661f16f8fb063beacb\",\"value\":5000000000,\"bounce\":false,\"allBalance\":false,\"payload\":\"\"}' --abi SafeMultisigWallet.abi.json --sign ${phrase}"
# echo $trans > trans.tmp.sh
# chmod +x trans.tmp.sh
# ./trans.tmp.sh >> log_step2.txt
# rm trans.tmp.sh

#Requesting the list of custodian public keys from the blockchain
custocheck="./tonos-cli run ${rawaddr} getCustodians {} --abi SafeMultisigWallet.abi.json"
echo $custocheck > custocheck.tmp.sh
chmod +x custocheck.tmp.sh
./custocheck.tmp.sh >> log_step2.txt
rm custocheck.tmp.sh
clear
echo -e "Succeeded\n\nLogs: ./log_step2.txt\n\nTo check the log:\ncat log_step2.txt"
cd ..
}


function phraseMenu {
  clear
  
  echo -e "\tSecret phrase: " 
  echo
  echo -e "\t1. Auto-generate phrase"
  echo -e "\t2. Input custom phrase"
  echo -en "\n\tEnter choice: "
  read -n 1 optionPhrase
  }

function networkMenu {
  clear
  
  echo -e "\tNetwork type: " 
  echo
  echo -e "\t1. MAIN"
  echo -e "\t2. DEV"
  echo -e "\t3. FLD"
  echo -en "\n\tEnter choice: "
}

function wcMenu {
  clear
  
  echo -e "\tWork Chain choice: " 
  echo
  echo -e "\t1. 0"
  echo -e "\t2. -1"
  echo -en "\n\tEnter choice: "
  read -n 1 optionWC
  }


#Menu
function menu {
clear

echo "OS type: " $os_type
echo
echo `pwd`
echo
echo -e "\tWallet deployment\n"
echo -e "\t1. Step 1"
echo -e "\t2. Check balance"
echo -e "\t3. Step 2"
echo -e "\t4. Show address"
echo -e "\t0. Exit"
echo -en "\n\tEnter number: "
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
4)
        showaddress ;;
*)
        clear
echo "Need to choose";;
esac
echo -en "\n\n\tPress any key to continue"
read -n 1 line
done
clear

exit