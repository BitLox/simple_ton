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
folder="tonos-cli"

if [ -d ${folder} ]
then
  echo "Folder ${folder} already exists!"
else
  echo "${folder} does not exist, fetching"
  echo
  #Download components and create a folder
  
  if [ "$os_type" == 'LINUX' ] 
    then
      wget https://github.com/tonlabs/tonos-cli/releases/download/v0.1.29/tonos-cli_v0.1.29_linux.tar.gz
      mkdir ./tonos-cli
      tar -xvf tonos-cli_v0.1.29_linux.tar.gz -C ./tonos-cli
      rm tonos-cli_v0.1.29_linux.tar.gz
  fi
  if [ "$os_type" == 'OSX' ]
    then
      # wget https://github.com/BitLox/tonos-cli/releases/download/v0.1.29/tonos-cli_v0.1.29_darwin.tar.gz
      wget http://localhost/tonos-cli_v0.1.29_darwin.tar.gz
      mkdir ./tonos-cli
      tar -xvf tonos-cli_v0.1.29_darwin.tar.gz -C ./tonos-cli
      rm tonos-cli_v0.1.29_darwin.tar.gz
  fi
  cd ./tonos-cli
  # wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.abi.json
  # wget https://github.com/tonlabs/ton-labs-contracts/raw/master/solidity/safemultisig/SafeMultisigWallet.tvc
  wget http://localhost/SafeMultisigWallet.abi.json
  wget http://localhost/SafeMultisigWallet.tvc
  #Network configuration
  # echo "Choose network, main or dev: "
  # read networkInput
  # network=$networkInput
  
  read -p "N of M wallet - Enter N :  " nValue
  clear
  read -p "N of M wallet - Enter M :  " mValue
  clear
  
  echo $nValue > N.txt
  echo $mValue > M.txt
  
  
#While & Case
while [ $? -ne 1 ]
do
        networkMenu
        case $optionNet in
1)
        setMain ;;
2)
        setDev ;;
esac
read -n 1 line
done
clear

#While & Case
while [ $? -ne 1 ]
do
        wcMenu
        case $optionWC in
1)
        setZero ;;
2)
        setMinusOne ;;
esac
read -n 1 line
done
clear



  
./tonos-cli config --url https://$network.ton.dev --wc $workchain >> log_step1.txt

max=$mValue
for (( i=1; i < max+1; i++ ))
do
  loopCount=$i
  #Creating a folder for keys
  eval "mkdir -p ${i}_data"
  
  #While & Case
  while [ $? -ne 1 ]
  do
          phraseMenu
          case $optionPhrase in
  1)
          setGenPhrase ;;
  2)
          setCustomPhrase ;;
  esac
  read -n 1 line
  done
  clear
  
  
  #Creating a temporary file for generating public key
  phrase=$(cat ${loopCount}_data/phrase.txt)
  
  # echo $phrase
  # phrase=$(cat ${i}_data/phrase.txt)
  pubkey="./tonos-cli genpubkey ${phrase}"
  echo $pubkey > pubkey.tmp.sh
  #Generating public key (3.1.2)
  chmod +x pubkey.tmp.sh
  ./pubkey.tmp.sh > ${loopCount}_data/pubkey.txt
  rm pubkey.tmp.sh
  #Sending a response to the log
  cat ${loopCount}_data/pubkey.txt >> log_step1.txt
  #Removing junk data from public key response
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -i -e '/Public*/! d' -e 's/P.* //' ${loopCount}_data/pubkey.txt
  fi
  if [ "$os_type" == 'OSX' ]
  then
    sed '/Public*/! d' ${loopCount}_data/pubkey.txt > ${loopCount}_data/pubkey.tmp.txt
    sed 's/P.* //' ${loopCount}_data/pubkey.tmp.txt > ${loopCount}_data/pubkey.txt
    rm ${loopCount}_data/pubkey.tmp.txt
  fi

  #Generating deployment key pair (3.2.1)
  phrase=$(cat ${loopCount}_data/phrase.txt)
  keypair="./tonos-cli getkeypair ${loopCount}_data/deploy.keys.json ${phrase}"
  echo $keypair > keypair.tmp.sh
  chmod +x keypair.tmp.sh
  ./keypair.tmp.sh >> log_step1.txt
  rm keypair.tmp.sh
  #Generating multisignature wallet address (Raw address)
  ./tonos-cli genaddr SafeMultisigWallet.tvc SafeMultisigWallet.abi.json --setkey ${loopCount}_data/deploy.keys.json --wc $workchain > ${loopCount}_data/rawaddr.txt
  #Sending a response to the log
  cat ${loopCount}_data/rawaddr.txt >> log_step1.txt
  #Removing junk data from raw address response
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -i -e '/Raw*/! d' -e 's/R.* //' ${loopCount}_data/rawaddr.txt
  fi
  if [ "$os_type" == 'OSX' ]
  then
    sed '/Raw*/! d' ${loopCount}_data/rawaddr.txt > ${loopCount}_data/rawaddr.tmp.txt
    sed 's/R.* //' ${loopCount}_data/rawaddr.tmp.txt > ${loopCount}_data/rawaddr.txt
    rm ${loopCount}_data/rawaddr.tmp.txt
  fi
  
  #Link to ton.live account
  rawaddr=$(cat ${loopCount}_data/rawaddr.txt)
  tonlive="https://${network}.ton.live/accounts?section=details&id=${rawaddr}"
  echo $tonlive > ${loopCount}_data/account.link.txt
  mkdir ${loopCount}_data/to_ton-keys_folder
  cp ./${loopCount}_data/rawaddr.txt ./${loopCount}_data/to_ton-keys_folder/hostname.addr
  cp ./${loopCount}_data/deploy.keys.json ./${loopCount}_data/to_ton-keys_folder/msig.keys.json
  mkdir ./${loopCount}_data/SWData
  # cd ..
  echo `pwd`
  # clear
done
baseaddr=$(cat 1_data/rawaddr.txt)
echo -e "Succeeded\n\nAll keys: ./data\n\nLogs: ./log_step1.txt\n\nTo check the log:\ncat log_step1.txt\n\nLink to your account (${network}.ton.live): ./account.link.txt\n\nSend some 1-2 tokens to your base address:\n${baseaddr}\n\nThen Step2.sh"

cd ..
fi
}
 


function  checkbalance() {
clear
# echo `pwd`
cd ./tonos-cli/${loopCount}_data
file="GetBalance.sh"

if [ -f ${file} ]
then
  ./GetBalance.sh > SWData/lastbalance.txt
  if [ "$os_type" == 'LINUX' ] 
  then
    sed -e '/bal/!d' -e 's/bal.*:       //' SWData/lastbalance.txt
    cd ../..
  fi
  if [ "$os_type" == 'OSX' ]
    then
    sed '/bal/!d' SWData/lastbalance.txt > SWData/lastbalance.tmp.txt
    sed 's/bal.*:       //' SWData/lastbalance.tmp.txt > SWData/lastbalance.txt
    rm SWData/lastbalance.tmp.txt
    cat SWData/lastbalance.txt
    cd ../..
  fi
else
  rawaddr=$(cat rawaddr.txt)
  balance=".././tonos-cli account ${rawaddr}"
  echo $balance > GetBalance.sh
  chmod +x GetBalance.sh
  clear
  cd ../.. 
  ./wallet.sh
fi
}

function  showaddress() {
  clear
  cat ./tonos-cli/${i}_data/rawaddr.txt 
}

function setGenPhrase() {
#Generating seed phrase (3.1.1)
# echo "in setGenPhrase"
./tonos-cli genphrase > ${loopCount}_data/phrase.txt
#Sending a response to the log
cat ${loopCount}_data/phrase.txt >> log_step1.txt
#Ydalenie lishnego iz frazu
if [ "$os_type" == 'LINUX' ] 
then
  sed -i -e 's/[^"]*//' -e '/^$/d' ${loopCount}_data/phrase.txt
fi
if [ "$os_type" == 'OSX' ]
then
sed 's/[^"]*//' ${loopCount}_data/phrase.txt > ${loopCount}_data/phrase.tmp.txt
  tr -d '\n' <    ${loopCount}_data/phrase.tmp.txt > ${loopCount}_data/phrase.txt 
  rm ${loopCount}_data/phrase.tmp.txt
fi
break;
}

function setCustomPhrase() {
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
  echo "MAIN" > network.txt
  break;
}

function setDev {
  network="NET";
  echo "NET" > network.txt
  break;
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

deploy="./tonos-cli deploy SafeMultisigWallet.tvc '{\"owners\":[\"0x${pubkey}\",\"0x${cosigner1Pubkey}\",\"0x${cosigner2Pubkey}\"],\"reqConfirms\":${nValue}}' --abi SafeMultisigWallet.abi.json --sign deploy.keys.json "
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
  echo `pwd`
  echo -e "\tSecret phrase: " 
  echo
  echo -e "\t1. Auto-generate phrase"
  echo -e "\t2. Input custom phrase"
  echo -en "\n\tEnter choice: "
  read -n 1 optionPhrase
  }

function networkMenu {
  clear
  echo `pwd`
  echo -e "\tNetwork type: " 
  echo
  echo -e "\t1. MAIN"
  echo -e "\t2. DEV"
  echo -en "\n\tEnter choice: "
  read -n 1 optionNet
  }

function wcMenu {
  clear
  echo `pwd`
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