#!/bin/bash
#
# Setup script to create SQS queues and assign
# appropriate permissions to SNS to allow publishing

# Configuration
REPO_NAME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && basename $(pwd) )" # Get the current folder name
AWS_ACCOUNT_ID=563280612930
AWS_REGION=us-east-1
ENV=(staging production)

# Export for AWS CLI
export AWS_REGION

# Reset
Reset='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Prevent running inside kms-example
if [[ "$REPO_NAME" == "kms-example" ]]; then
  echo -e "${Red}Cannot run setup inside of kms-example.\n${Reset}Please clone the new microservice from Github and run setup there."
  exit 1
fi

# Rename local files
mod=$(cat go.mod)
if [[ $mod == "module github.com/kyani-inc/kms-example"* ]]; then
  printf "${Yellow}➜${Reset} Renaming ${Yellow}kms-example${Reset} to: ${Blue}${REPO_NAME}${Reset}..."
  find . -type f \( -name "*.go" -o -name "*.md" -o -name "env-sample" -o -name "go.mod" \) -print0 | \
    xargs -0 sed -i '' -e  "s|kms-example|$REPO_NAME|g"
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  printf "${Yellow}➜${Reset} Renaming KMS Service Name: ${Blue}${REPO_NAME}${Reset}..."
  sed -i '' -e "s|kms.ServiceName(\"example\")|kms.ServiceName(\"${REPO_NAME#"kms-"}\")|g" src/main.go
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  printf "${Yellow}➜${Reset} Committing changes to GitHub...\n"
  git add -A
  git commit -m "Rename kms-example to $REPO_NAME"
  git push

  printf "${Yellow}➜${Reset} Copying ${Yellow}env-sample${Reset} to: ${Blue}env${Reset}..."
  cp env-sample env
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;
fi
echo -e "-------------------------------------------"

for ENV in ${ENV[*]}; do
  echo -e "Creating ${Blue}${REPO_NAME}${Reset} environment: ${Yellow}${ENV}${Reset}"

  # Create ECR repository
  printf " ${Yellow}➜${Reset} Creating ${Yellow}ECR${Reset} Repository: ${Blue}${REPO_NAME}-${ENV}${Reset}..."
  results=$(aws ecr create-repository --repository-name "${REPO_NAME}-${ENV}" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Create main queue
  printf " ${Yellow}➜${Reset} Creating ${Yellow}SQS${Reset} Queue: ${Blue}${REPO_NAME}__${ENV}${Reset}..."
  input=$(jq \
    --arg queue_name "${REPO_NAME}__${ENV}" \
    '.QueueName=$queue_name | .Attributes={} | .tags = {}' <<< $(aws sqs create-queue --generate-cli-skeleton))
  results=$(aws sqs create-queue --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Create dead-letter queue
  printf " ${Yellow}➜${Reset} Creating Dead Letter Queue: ${Blue}${REPO_NAME}-dead__${ENV}${Reset}..."
  input=$(jq \
    --arg queue_name "${REPO_NAME}-dead__${ENV}" \
    '.QueueName=$queue_name | .Attributes={} | .tags = {}' <<< $(aws sqs create-queue --generate-cli-skeleton))
  results=$(aws sqs create-queue --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Assign SNS permissions
  printf " ${Yellow}➜${Reset} Assigning ${Yellow}SQS${Reset} Queue Permissions: ${Blue}${REPO_NAME}__${ENV}${Reset}..."
  input=$(jq \
    --arg queue_url "https://sqs.${AWS_REGION}.amazonaws.com/${AWS_ACCOUNT_ID}/${REPO_NAME}__${ENV}" \
    --arg redrive_policy "{ \"deadLetterTargetArn\": \"arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REPO_NAME}-dead__${ENV}\", \"maxReceiveCount\": \"5\" }" \
    --arg policy "{\"Version\":\"2012-10-17\",\"Id\":\"arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REPO_NAME}__${ENV}/SQSDefaultPolicy\",\"Statement\":[{\"Sid\":\"Sid1589413258867\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":\"SQS:SendMessage\",\"Resource\":\"arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REPO_NAME}__${ENV}\",\"Condition\":{\"ArnEquals\":{\"aws:SourceArn\":\"arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:kms__${ENV}\"}}}]}" \
    '.QueueUrl=$queue_url | .Attributes={} | .Attributes.RedrivePolicy=$redrive_policy | .Attributes.Policy=$policy' <<< $(aws sqs set-queue-attributes --generate-cli-skeleton))
  results=$(aws sqs set-queue-attributes --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Subscribe queues to SNS with filter policy
  printf " ${Yellow}➜${Reset} Subscribing ${Yellow}Queue${Reset} to ${Yellow}SNS${Reset} topic: ${Blue}kms__${ENV}${Reset}..."
  input=$(jq \
    --arg topic_arn "arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:kms__${ENV}" \
    --arg protocol "sqs" \
    --arg endpoint "arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REPO_NAME}__${ENV}" \
    --argjson attributes "{ \"FilterPolicy\": \"{\\\"EventName\\\": [\\\"kyani.void\\\"] }\" }" \
    '.TopicArn=$topic_arn | .Protocol=$protocol | .Endpoint=$endpoint | .Attributes=$attributes' <<< $(aws sns subscribe --generate-cli-skeleton))
  results=$(aws sns subscribe --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Create IAM Role
  printf " ${Yellow}➜${Reset} Creating ${Yellow}IAM${Reset} Role: ${Blue}${REPO_NAME}__${ENV}${Reset}..."
  input=$(jq \
    --arg name "${REPO_NAME}__${ENV}" \
    --arg trust_relationships "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" \
    --arg description "Second-generation Kyani Microservice for ${REPO_NAME}" \
    '.RoleName=$name | .AssumeRolePolicyDocument=$trust_relationships | .Description=$description | del(.Path) | del(.PermissionsBoundary) | del(.Tags) | del(.MaxSessionDuration)' <<< $(aws iam create-role --generate-cli-skeleton))
  results=$(aws iam create-role --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Attach KMS v2 Policy
  printf " ${Yellow}➜${Reset} Attaching KMS v2 ${Yellow}Policy${Reset} to Role: ${Blue}${REPO_NAME}__${ENV}${Reset}..."
  input=$(jq \
    --arg name "${REPO_NAME}__${ENV}" \
    --arg policy "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/Kyani-KMS-v2__${ENV}" \
    '.RoleName=$name | .PolicyArn=$policy' <<< $(aws iam attach-role-policy --generate-cli-skeleton))
  results=$(aws iam attach-role-policy --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Create inline policy for SQS
  printf " ${Yellow}➜${Reset} Authorizing Role for ${Yellow}SQS${Reset} Queue: ${Blue}${REPO_NAME}__${ENV}${Reset}..."
  input=$(jq \
    --arg name "${REPO_NAME}__${ENV}" \
    --arg policy "SQS" \
    --arg doc "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"VisualEditor0\",\"Effect\":\"Allow\",\"Action\":[\"sqs:DeleteMessage\",\"sqs:ChangeMessageVisibility\",\"sqs:DeleteMessageBatch\",\"sqs:SendMessageBatch\",\"sqs:ReceiveMessage\",\"sqs:SendMessage\",\"sqs:ChangeMessageVisibilityBatch\"],\"Resource\":\"arn:aws:sqs:${AWS_REGION}:${AWS_ACCOUNT_ID}:${REPO_NAME}__${ENV}\"}]}" \
    '.RoleName=$name | .PolicyName=$policy | .PolicyDocument=$doc' <<< $(aws iam put-role-policy --generate-cli-skeleton))
  results=$(aws iam put-role-policy --cli-input-json "$input" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # # Create CloudWatch log group
  logGroup="/aws/ecs/${ENV}/${REPO_NAME}"
  printf " ${Yellow}➜${Reset} Creating ${Yellow}Log${Reset} Group: ${Blue}${logGroup}${Reset}..."
  results=$(aws logs create-log-group --log-group-name "$logGroup" 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  # Update retention settings
  printf " ${Yellow}➜${Reset} Setting ${Yellow}Log${Reset} Retention: ${Blue}${logGroup}${Reset}..."
  results=$(aws logs put-retention-policy --log-group-name "$logGroup" --retention-in-days 90 2>&1)
  if [ $? -eq 0 ]; then echo -e "${Green}OK${Reset}"; else echo -e "${Red}FAILED${Reset}"; echo -e "$results\n"; fi;

  echo -e "---------------------------------------------------------------${dashes}"
done


# TODO automate service creation with sensible defaults
