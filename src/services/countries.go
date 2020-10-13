package services

import (
	"context"
	"os"
	"time"

	"github.com/kyani-inc/kms"
	"github.com/kyani-inc/kms/v2/log"
	pb "github.com/kyani-inc/proto/countries"
)

// Countries is an exported client used to connect to kms-countries
var Countries pb.CountryServiceClient

// setupCountries connects to kms-countries as an example
func setupCountries(ctx context.Context) {
	log, ctx := log.FromContext(ctx, "setupCountries")

	// Timeout connection
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	// Connect to gRPC service
	env := os.Getenv("KMS_COUNTRIES_ENV")
	log.Infow("connecting to kms-countries", "env", env)
	conn, err := kms.ConnectRPC(ctx, kms.ServiceName("countries"), env)
	if err != nil {
		panic("error:" + err.Error())
	}

	// New client
	Countries = pb.NewCountryServiceClient(conn)
}
