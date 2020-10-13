package rest

import (
	"github.com/kyani-inc/kms-example/src/rest/hello"
	"github.com/labstack/echo/v4"

	// Import REST documentation for built-in Swagger support
	_ "github.com/kyani-inc/kms-example/src/rest/docs"
)

// Insert your Swag documentation comments here
// https://github.com/swaggo/swag#declarative-comments-format

// @title Example API
// @version 1.0
// @description This is an example KMSv2 API
// @contact.name Kyäni DevOps
// @contact.email devops@kyanicorp.com
// @BasePath /
// @query.collection.format multi
// @schemes http

// Setup configures the service's Echo (REST) server
func Setup(server *echo.Echo) {
	hello.Setup(server)
}
