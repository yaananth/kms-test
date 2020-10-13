#!/bin/sh

# Log only the basename
TASK_DEFINITION=$(basename "$TASK_DEFINITION")

echo "
------------------------------------
Cluster: ${CLUSTER}
Service: ${SERVICE}
Task Definition: ${TASK_DEFINITION}
Image: ${IMAGE}
------------------------------------\n"

# Grab commit message from event
COMMIT_SHA=$(cat ${GITHUB_EVENT_PATH} | jq -r .after)

# Check if that commit is associated to a pull request
ISSUE=$(curl -s -S \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  --header "Content-Type: application/json" \
  "https://api.github.com/search/issues?q=${COMMIT_SHA}")

# Check for matching pull request (issue)
TOTAL_COUNT=$(echo "$ISSUE" | tr '\r\n' ' ' | jq -r .total_count)
if [ "$TOTAL_COUNT" -eq 0 ]; then
  echo "Skipping PR comments, no matching pull requests"
  exit 0
fi

# Build comment message
COMMENT="## Deployment Details

**Cluster:** [${CLUSTER}](https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/${CLUSTER})
**Service:** [${SERVICE}](https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/${CLUSTER}/services/${SERVICE}/tasks)
**Task Definition:** \`${TASK_DEFINITION}\`
**Image:** \`${IMAGE}\`

Build was successfully deployed to the \`${ENVIRONMENT}\` environment.

[View Logs](https://github.com/kyani-inc/${KMS_NAME}/actions/runs/${RUN_ID})
"
PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')

# Publish comment to each matching PR
COMMENTS_URLS=$(echo "$ISSUE" | tr '\r\n' ' ' | jq -r .items[].comments_url)

echo "$COMMENTS_URLS" | while IFS= read -r COMMENT_URL; do
  # Comment URL is empty somehow
  if [ -z "$COMMENT_URL" ]; then
    # Comments URL is empty
    echo "Skipping PR comment, URL was empty: ${COMMENT_URL}"
    continue
  fi

  printf "Posting deployment details on Pull Request: ${COMMENT_URL}..."
  RESP=$(curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENT_URL}")
  if [ $(echo "$RESP" | tr '\r\n' ' ' | jq -r ".id") -gt 0 ]; then
    echo " OK"
  else
    echo " FAILED"
    echo "$RESP"
  fi
done
