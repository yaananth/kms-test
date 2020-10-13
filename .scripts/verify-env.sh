#!/bin/sh

ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')
ENV_VARS=$(envi g -i "${KMS_NAME}__${ENVIRONMENT}" -o json)
VALID=true

# Make sure PORT is 80
echo "Checking PORT == :80"
PORT=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "PORT") | .value')
if [ "$PORT" != ":80" ]; then
  echo "  FAIL – Invalid PORT variable. Must be set to :80 on ${ENVIRONMENT}"
  VALID=false
else
  echo "  OK"
fi;

# Make sure KMS_ENV matches environment
echo "Checking KMS_ENV == ${ENVIRONMENT}"
KMS_ENV=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "KMS_ENV") | .value')
if [ "$KMS_ENV" != "$ENVIRONMENT" ]; then
  echo "  FAIL – Invalid KMS_ENV variable. Must be set to ${ENVIRONMENT}"
  VALID=false
else
  echo "  OK"
fi;

# Make sure KMS_WORKER_QUEUE_ARN is not empty (even if we're not using workers at this time)
EXPECTED="arn:aws:sqs:us-east-1:563280612930:${KMS_NAME}__${ENVIRONMENT}"
echo "Checking KMS_WORKER_QUEUE_ARN == ${EXPECTED}"
KMS_WORKER_QUEUE_ARN=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "KMS_WORKER_QUEUE_ARN") | .value')
if [ "$KMS_WORKER_QUEUE_ARN" != "$EXPECTED" ]; then
  echo "  FAIL – Invalid KMS_WORKER_QUEUE_ARN variable. Must be set to ${EXPECTED}"
  VALID=false
else
  echo "  OK"
fi;

# Make sure KMS_WORKER_TOPIC_ARN is not empty (even if we're not using workers at this time)
EXPECTED="arn:aws:sns:us-east-1:563280612930:kms__${ENVIRONMENT}"
echo "Checking KMS_WORKER_TOPIC_ARN == ${EXPECTED}"
KMS_WORKER_TOPIC_ARN=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "KMS_WORKER_TOPIC_ARN") | .value')
if [ "$KMS_WORKER_TOPIC_ARN" != "$EXPECTED" ]; then
  echo "  FAIL – Invalid KMS_WORKER_TOPIC_ARN variable. Must be set to ${EXPECTED}"
  VALID=false
else
  echo "  OK"
fi;

# Make sure AWS_REGION is set (for dynamo and logging)
EXPECTED="us-east-1"
echo "Checking AWS_REGION == ${EXPECTED}"
AWS_REGION=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "AWS_REGION") | .value')
if [ "$AWS_REGION" != "$EXPECTED" ]; then
  echo "  FAIL – Invalid AWS_REGION variable. Must be set to ${EXPECTED}"
  VALID=false
else
  echo "  OK"
fi;

# Make sure AWS_ACCESS_KEY_ID is empty (no credential leaks please...)
echo "Checking AWS_ACCESS_KEY_ID is empty"
AWS_ACCESS_KEY_ID=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "AWS_ACCESS_KEY_ID") | .value')
if [ "$AWS_ACCESS_KEY_ID" != "" ]; then
  echo "  FAIL – Do not set AWS_ACCESS_KEY_ID in ${ENVIRONMENT}, ECS tasks use IAM Assumed Roles"
  VALID=false
else
  echo "  OK"
fi;

# Make sure AWS_SECRET_KEY is empty (no credential leaks please...)
echo "Checking AWS_SECRET_KEY is empty"
AWS_SECRET_KEY=$(echo "$ENV_VARS" | jq -r '.[]? | select(.name == "AWS_SECRET_KEY") | .value')
if [ "$AWS_SECRET_KEY" != "" ]; then
  echo "  FAIL – Do not set AWS_SECRET_KEY in ${ENVIRONMENT}, ECS tasks use IAM Assumed Roles"
  VALID=false
else
  echo "  OK"
fi;

# TODO Verify env-sample is up to date

echo ""
if [ "$VALID" = false ]; then
  echo "███████  █████  ██ ██      ███████ ██████  "
  echo "██      ██   ██ ██ ██      ██      ██   ██ "
  echo "█████   ███████ ██ ██      █████   ██   ██ "
  echo "██      ██   ██ ██ ██      ██      ██   ██ "
  echo "██      ██   ██ ██ ███████ ███████ ██████  "
  echo "\nOne or more environment variables were incorrect or missing. Please correct the errors and run the deployment again.\n"
  exit 1
else
  echo "██████   █████  ███████ ███████ ███████ ██████  "
  echo "██   ██ ██   ██ ██      ██      ██      ██   ██ "
  echo "██████  ███████ ███████ ███████ █████   ██   ██ "
  echo "██      ██   ██      ██      ██ ██      ██   ██ "
  echo "██      ██   ██ ███████ ███████ ███████ ██████  "
  echo "\nAll environment variables were validated successfully!\n"
fi;
