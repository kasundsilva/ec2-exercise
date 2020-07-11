#!/bin/bash

# exit when an error occurs
set -e

# create the output folder if it doesn't exist
mkdir -pv output

echo ""
echo "################################################################################################################"
echo "Preparing the variables..."
echo "################################################################################################################"
echo ""

premisesIP=$(curl -s http://ipv4.icanhazip.com)

echo "------------- Reading the input file..."
echo ""

stacksRaw=$(jq . input/stacks.json)

echo
echo "------------- global variable values:"
echo
echo "premisesIP: $premisesIP"

checkStack(){
  echo ""
  echo "################################################################################################################"
  echo "Getting stack output of $stackName..."
  echo "################################################################################################################"
  echo ""

  set +e
  stackInfo=$(aws cloudformation describe-stacks \
  --stack-name "$stackName" \
  --region "$region" \
  --profile "$profile")
  set -e

  echo "stackInfo: $stackInfo"
  # TODO: add a check to look for CREATE_COMPLETE StackStatus. if $stackInfo is not blank and StackStatus
  # TODO: is not CREATE_COMPLETE (maybe check for all possible negative ones instead), delete the stack
  # TODO: or stop here with a message asking the user to fix it in the console
  if [ "$stackInfo" != "" ] && [ "$setOutput" = true ]; then
    outputs="$(echo "$stackInfo" | jq -r '.Stacks[].Outputs')"
  fi
}

applyTemplate(){
  echo ""
  echo "################################################################################################################"
  echo "Creating stack named $stackName..."
  echo "################################################################################################################"
  echo ""

  if [ "$outputs" != "" ]; then

    # transform the output into input
    outputs=$(echo "$outputs" | sed \
    -e "s|OutputKey|ParameterKey|g" \
    -e "s|OutputValue|ParameterValue|g")

    # add them to the list of parameters
    parameters=$(echo "$parameters" | jq ". += $outputs")
  fi

  echo
  echo "------------- variables:"
  echo
  echo "profile: $profile"
  echo "region: $region"
  echo "moduleName: $moduleName"
  echo "stackName: $stackName"
  echo "outputs: $outputs"
  echo

  if [ "$moduleName" = "compute" ]; then
    echo
    echo "------------- checking if the ec2 key pair exists..."
    echo

    set +e
    keypair=$(aws ec2 describe-key-pairs \
    --region "$region" \
    --profile "$profile" \
    --key-name "$stackName-admin")
    set -e

    if [ "$keypair" = "" ]; then
      echo
      echo "------------- creating the ec2 key pair..."
      echo

      aws ec2 create-key-pair \
      --region "$region" \
      --profile "$profile" \
      --key-name "$stackName-admin" > "output/$stackName-admin.json"

      echo
      echo "------------- creating the .pem file..."
      echo

      jq -r .KeyMaterial "output/$stackName-admin.json" > "output/$stackName-admin.pem"
    fi

    parameters=$(echo "$parameters" | jq ". += [{\"ParameterKey\": \"PremisesIP\",\"ParameterValue\": \"$premisesIP\"}]")
  fi

  echo
  echo "------------- variables:"
  echo
  echo "parameters: $parameters"
  echo

  echo
  echo "------------- applying the template..."
  echo

  creationResult=$(aws cloudformation "create-stack" \
  --stack-name "$stackName" \
  --region "$region" \
  --template-body "file://modules/$moduleName/$moduleName.yaml" \
  --parameters "$parameters" \
  --capabilities CAPABILITY_IAM \
  --profile "$profile")
  echo "creationResult: $creationResult"
  echo

  stackId=$(echo "$creationResult" | jq -r '.StackId')
  echo "stackId: $stackId"
  echo

  aws cloudformation wait stack-create-complete \
  --region "$region" \
  --profile "$profile" \
  --stack-name "$stackId"
}

echo
echo "------------- record variable values:"
echo

for stack in $(echo "$stacksRaw" | jq -r '.[] | @base64'); do
  originalStackName=$(echo "$stack" | base64 -di | jq -r '.StackName') # to be modified in the module loop
  profile=$(echo "$stack" | base64 -di | jq -r '.Profile')
  region=$(echo "$stack" | base64 -di | jq -r '.Region')
  counter=0
  for module in $(echo "$stack" | base64 -di | jq -r '.Modules[] | @base64'); do
    module=$(echo "$module" | base64 -di | jq -r .)
    moduleName=$(echo "$module" | jq -r '.Name')
    stackName="$originalStackName-$moduleName"
    parameters=$(echo "$module" | jq -r '.Parameters')

    # check if stack exists and only set the output if in the first iteration
    if [ "$counter" -eq 0 ]; then
      setOutput=true
    else
      setOutput=false
    fi
    checkStack

    # create the stack if it doesn't already exist
    if [ "$stackInfo" = "" ]; then
      applyTemplate
    fi

    # get the output for the next iteration
    setOutput=true
    checkStack

    counter=$((counter+1))
  done
done


