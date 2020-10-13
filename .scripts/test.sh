#!/bin/sh

killall ${KMS_NAME} > /dev/null 2>&1

printf "Starting test server... \t"
PORT=:${TEST_PORT} KMS_TESTING=true ./bin/${KMS_NAME} > test.log 2>&1 &
echo "$!" > test.pid

tearDown () {
  printf "Stopping test server... \t"
  kill -9 `cat test.pid` > /dev/null 2>&1
  echo "OK"
  test -f test.pid && rm test.pid
  test -f test.log && rm test.log
}
trap tearDown EXIT

i=1;
while [ $i -gt 0 ]; do
  LISTENING=$(nc -z 127.0.0.1 ${TEST_PORT} > /dev/null 2>&1 && echo "1" || echo "0");
  if [ "$LISTENING" = "1" ]; then
    echo "OK"
    break
  fi;
  if [ "$i" -gt 30 ]; then
    echo "FAILED"
    echo "Server failed to listen on port ${TEST_PORT} after 30s"
    cat test.log
    exit 1
  fi;
  i=$((i+1))
  sleep 1
done

echo "Running tests..."
PORT=:${TEST_PORT} KMS_TESTING=true go test -v ./...
PASS=$?

echo ""
if [ "$PASS" = "1" ]; then
  echo "███████  █████  ██ ██      ███████ ██████  "
  echo "██      ██   ██ ██ ██      ██      ██   ██ "
  echo "█████   ███████ ██ ██      █████   ██   ██ "
  echo "██      ██   ██ ██ ██      ██      ██   ██ "
  echo "██      ██   ██ ██ ███████ ███████ ██████  "
  echo "\nOne or more tests failed. Please correct the errors and run the tests again.\n"
  exit 1
else
  echo "██████   █████  ███████ ███████ ███████ ██████  "
  echo "██   ██ ██   ██ ██      ██      ██      ██   ██ "
  echo "██████  ███████ ███████ ███████ █████   ██   ██ "
  echo "██      ██   ██      ██      ██ ██      ██   ██ "
  echo "██      ██   ██ ███████ ███████ ███████ ██████  "
  echo "\nAll tests passed successfully!\n"
fi;
