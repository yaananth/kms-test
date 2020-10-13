#!/bin/sh

if [ ! -d "src/rest" ]; then
  echo "Skipping Swagger documentation, service does not have a src/rest folder"
  exit 0
fi

go get github.com/swaggo/swag/cmd/swag
swag init --output ./src/rest/docs --generalInfo src/rest/rest.go --parseDependency
