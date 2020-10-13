package hello

import (
	"net/http"

	"github.com/kyani-inc/kms-example/src/app/example"
	"github.com/kyani-inc/kms/v2/log"
	pb "github.com/kyani-inc/proto/example"
	"github.com/labstack/echo/v4"
)

// Setup configures the service's Echo (REST) server
func Setup(server *echo.Echo) {
	g := server.Group("/hello")
	g.GET("/:name", SayHello)
}

type SayHelloResponse struct {
	Reply string `json:"reply" example:"Hello TestUser, nice to meet you!"`
}

type RESTError struct {
	Message string `json:"message" example:"missing name parameter"`
}

func (re *RESTError) Error() string {
	return re.Message
}

// SayHello is the route for saying hello
// SayHello godoc
// @Summary Say hello to someone, publishing an event for testing
// @Accept  json
// @Produce  json
// @Param name path string true "name of the person to greet" default(TestUser)
// @Success 200 {object} SayHelloResponse
// @Failure 400 {object} RESTError
// @Router /hello/{name} [get]
func SayHello(c echo.Context) error {
	// Generate a scoped logger for this method
	log, ctx := log.FromContext(c.Request().Context(), "SayHello")
	log.Infow("say hello request", "ip", c.RealIP(), "headers", c.Request().Header)

	// Grab name from query string
	name := c.Param("name")
	if name == "" {
		return c.JSON(http.StatusBadRequest, RESTError{
			Message: "missing name parameter",
		})
	}

	// Build our person using Proto type
	person := &pb.Person{
		Name: name,
	}

	// Say hello using the app package
	answer, err := example.SayHello(ctx, person)
	if err != nil {
		log.Errorf("error saying hello: %v", err)
		return c.JSON(http.StatusBadRequest, RESTError{
			Message: err.Error(),
		})
	}

	// Return it
	return c.JSON(http.StatusOK, SayHelloResponse{
		Reply: answer,
	})
}
