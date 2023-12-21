#!/bin/bash
source ~/.profile

# Default variable values
destroy=false

# Function to display script usage
usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Options:"
 echo " -h, --help      Display this help message"
 echo " -d, --destroy   Destroy infrastructure"
}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -d | --destroy)
        echo "Destroy flag detected"
        destroy=true
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}

# Main script execution
handle_options "$@"

printf "%s" "Enter App Name: "
read app_name
printf "%s" "Enter AWS Region: "
read aws_region

if [ "$destroy" = true ]; then
  printf "%s" "Press Enter to DESTROY ALL CREATED INFRASTRUCTURE! This CANNOT be undone!!"
  read enter
  printf "%s" "ARE YOU SURE!! THIS IS NOT REVERSIBLE!!"
  read enter
  echo "DESTROYING IN 3"
  sleep 1
  echo "2"
  sleep 1
  echo "1"
  sleep 1
  echo "COMMENCING DESTRUCTION!"

  repository_clone_url=$(terraform -chdir="./2-github-codestar/" output -raw repository_clone_url)
  repository_name=$(terraform -chdir="./2-github-codestar/" output -raw repository_name)  
  codestar_connection=$(terraform -chdir="./2-github-codestar/" output -raw codestar_connection)  
  codestar_connection_arn=$(terraform -chdir="./2-github-codestar/" output -raw codestar_connection_arn)  
  
  terraform -chdir="./3-pipeline-codefront/" destroy -auto-approve -var app_name=$app_name \
  -var aws_region=$aws_region \
  -var codestar_connection_arn=$codestar_connection_arn \
  #-var github_owner="" \
  -var github_repo_name=$repository_name

  terraform -chdir="./2-github-codestar/" destroy -auto-approve -var aws_region=$aws_region

  echo "Destroying S3 Backend..."
  terraform -chdir="./1-terraform-state-bucket/" destroy -auto-approve -var aws_region=$aws_region

else
  echo "Setting up S3 backend..."
  terraform -chdir="./1-terraform-state-bucket/" init -var app_name=$app_name -var aws_region=$aws_region
  terraform -chdir="./1-terraform-state-bucket/" apply -var app_name=$app_name -var aws_region=$aws_region

  echo "Setting up AWS Resources"
  echo "Creating GitHub Repo and CodeStar Connection... You will have to activate it afterwards"
  echo "To begin, provide your Github Token. See more at https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens"
  terraform -chdir="./2-github-codestar/" init \
  -backend-config="bucket=${app_name}-terraform-state-bucket" \
  -backend-config="region=${aws_region}"
  terraform -chdir="./2-github-codestar/" apply -var aws_region=$aws_region

  echo "Cloning Repo locally and installing React Vite"
  # clone repo and install react vite
  git clone $repository_clone_url
  cd $repository_name
  brew install nvm
  nvm install --lts && nvm use --lts
  npm create vite@latest ./ -- --template react

  # add buildspec.yml so CodeBuild knows what to do
  cp ../buildspec.yml .

  git add -A
  git commit -m "Bootstrap vite"
  git push
  cd ..
  rm -rf $repository_name

  # capture repository url and name and create codestar (go activate it)
  repository_clone_url=$(terraform -chdir="./2-github-codestar/" output -raw repository_clone_url)
  repository_name=$(terraform -chdir="./2-github-codestar/" output -raw repository_name)  
  codestar_connection_arn=$(terraform -chdir="./2-github-codestar/" output -raw codestar_connection_arn)  

  echo "Now navigate to your AWS Console and activate your CodeStar Connection: ${codestar_connection}"
  printf "%s" "Then press Enter to continue"
  read enter

  printf "%s" "Provide the name of the owner of the GitHub Repo"
  read github_repo_owner

  echo "Using the activated CodeStar Connection to create Code Pipeline and a CloudFront Distribution"
  terraform -chdir="./3-pipeline-codefront/" init \
  -backend-config="bucket=${app_name}-terraform-state-bucket" \
  -backend-config="region=${aws_region}"
  terraform -chdir="./3-pipeline-codefront/" apply -var app_name=$app_name \
  -var aws_region=$aws_region \
  -var codestar_connection_arn=$codestar_connection_arn \
  -var github_owner=$github_repo_owner \
  -var github_repo_name=$repository_name

  domain_name=$(terraform -chdir="./3-pipeline-codefront/" output -raw domain_name)
  echo "Cloudfront Distribution created on ${domain_name}"
  
fi