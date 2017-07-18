#!/bin/bash

#aws cloudformation describe-stacks --stack-name arundemo | jq ".Stacks[0].Outputs" | jq -c '.[] | select(.OutputKey | contains("WebsiteURL")) | .OutputValue'

#stackJson="{ 'StackId': 'arn:aws:cloudformation:us-east-1:123456789012:stack/myteststack/466df9e0-0dff-08e3-8e2f-5088487c4896' }"

#aws cloudformation create-stack --stack-name myteststack --template-body file://helloworld-cfn-template.json --parameters ParameterKey=KeyPairName,ParameterValue=TestKey ParameterKey=SubnetIDs,ParameterValue=SubnetID1\\,SubnetID2
echo ""
echo "***************************************************************************************************************************"
echo ""
echo "Correct Usage:"
echo ""
echo "./createHelloService.sh template-file keypairname subnetids stackname"
echo ""
echo "ATTENTION!"
echo "1. Give correct keypair name. If the keypair is not found new keypair with the name will be created and pem saved in the script folder"
echo "2. subnetids is a comma seperated string of subnet ids. Please ensure that they belong to same VPC and are in different Az's"
echo "3. subnetids format should be single quoted with comma escaped. For eg. 'subnet-3c4c5f58\,subnet-ee010598'"
echo "4. the script assumes that the user initiating it has all requiste permissions"
echo "5. the ELB is lauched in default security group. Ensure that the SG allows HTTP and HTTPS access"
echo ""
echo "***************************************************************************************************************************"
echo ""
echo "Type y if want to proceed"
echo "y/n?"
read choice

if [[ "$choice" != "y" ]]
then
   echo "no"
   exit
fi

if [[ (-z "$1")  || (-z "$2") || (-z "$3") || (-z "$4") ]]
then
echo "Missing parameters: template file, keypairs and subnets needed.Make sure to supply correct subnets. Key will be created  "
exit
fi


for i in $(echo $3 | sed "s/\\\,/ /g")
do    
    # call your procedure/other scripts here below
	if [[ -z "$subnets1" ]]
	then
    subnets1="$i"        	
	else
	subnets1="$subnets1 $i" 
    	
	fi
done

subnetsInAWS=$(aws ec2 describe-subnets --subnet-ids $subnets1)

if [[ -z "$subnetsInAWS" ]] 
then 
echo "error:"
echo "stopping the script. No changes made in AWS."
exit
fi

VpcId=$(echo "$subnetsInAWS" | jq '.Subnets[0].VpcId')


keyInAWS=$(aws ec2 describe-key-pairs | jq '.KeyPairs' | jq -c --arg v $2 '.[] | select(.KeyName | contains($v))')

#keyInAWS=$(aws ec2 describe-key-pairs | jq '.KeyPairs' | jq -c --arg v $2 '.[] | select(.KeyName==$v)')

#check if key is empty
if [[ -z "$keyInAWS" ]]
then
	echo "keypair does not exist. Creating new key-pair $1"
	newKeyPair=$(aws ec2 create-key-pair --key-name $2 --query 'KeyMaterial' --output text)
	echo "$newKeyPair" >> "$2.pem"
fi

echo ""
echo "Stack creation initiated. This process will take some time."
#test="aws cloudformation create-stack --stack-name $4 --template-body file://$1 --parameters ParameterKey=KeyName,ParameterValue=$2 ParameterKey=Subnets,ParameterValue=$3 ParameterKey=VpcId,ParameterValue=$VpcId"
#echo $test
#exit
stackCreation=$(aws cloudformation create-stack --stack-name $4 --template-body file://$1 --parameters ParameterKey=KeyName,ParameterValue=$2 ParameterKey=Subnets,ParameterValue=$3  ParameterKey=VpcId,ParameterValue=$VpcId)

stackStatus=$(aws cloudformation describe-stacks --stack-name $4 | jq -r ".Stacks[0].StackStatus")

while [ "$stackStatus" != "CREATE_COMPLETE" ] && [ "$stackStatus" != "CREATE_FAILED" ] 
   do 
     sleep 30
	 stackStatus=$(aws cloudformation describe-stacks --stack-name $4 | jq -r ".Stacks[0].StackStatus")
done

if [ "$stackStatus" == "CREATE_COMPLETE" ]; then
      webURL=$(aws cloudformation describe-stacks --stack-name $4 | jq ".Stacks[0].Outputs" | jq -r '.[] | select(.OutputKey | contains("WebsiteURL")) | .OutputValue')
      echo ""
	  echo "Stack successfully created"
	  echo ""
	  echo "The service can be accessed at the URL given below"
	  echo $webURL	  
else
      echo "CREATE FAILED"
	  echo "Check Logs for details or contact Account Administrator"
fi
