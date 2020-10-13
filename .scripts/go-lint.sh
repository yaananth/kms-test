#!/bin/sh

set +e
FILES=$(goimports -l $(find . -type f -name '*.go' -not -path "./vendor/*"))

# No files to change, continue on
if [ -z "$FILES" ]; then
  echo "\nAll files are formatted correctly!"
  exit 0
fi

echo "\n#################################"
echo "  GOIMPORTS FORMATTING REQUIRED  "
echo "#################################"
echo "\nThe following files have incorrect goimports formatting:"
echo "$FILES"
echo "\nPlease run goimports to apply proper formatting: goimports -w ."

FMT_OUTPUT=""
for file in ${FILES}; do
  FILE_DIFF=$(goimports -d -e "${file}")
  FMT_OUTPUT="${FMT_OUTPUT}
  <details><summary><code>${file}</code></summary>

  \`\`\`diff
  ${FILE_DIFF}
  \`\`\`
  </details>
  "
done
COMMENT="## ⚠ Go Formatting Errors
${FMT_OUTPUT}
-------------------------
Please run \`goimports -w .\` to apply the proper formatting.
"

# Publish comment to the PR
PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT}" '.body = $body')
COMMENTS_URL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data "${PAYLOAD}" "${COMMENTS_URL}" > /dev/null

exit 1
