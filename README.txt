Correct Usage:

./createHelloService.sh template-file keypairname subnetids stackname"

For eg.
./createHelloService.sh helloworld-cfn-template.json arundemo 'subnet-3c4c5f58\,subnet-ee010598' testStack

ATTENTION!
1. Ensure demoTemplate.json is the same directory as the script
2. Ensure that default SG for the VPC (of subnetids) is allows HTTP and HTTPS access 
(the ELB is lauched in default security group. Ensure that the SG allows HTTP and HTTPS access)
3. subnetids is a comma seperated string of subnet ids. Please ensure that they belong to same VPC and are in different Az's
4. subnetids format should be single quoted with comma escaped. For eg. 'subnet-3c4c5f58\,subnet-ee010598'
5. Give correct keypair name. If the keypair is not found new keypair with the name will be created and pem saved in the script folder
6. the script assumes that the user initiating it has all requiste permissions


For further details on cloudformation template used here: refer helloworld-cfn-template-description.txt
