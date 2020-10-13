package services

import (
	"context"

	"github.com/kyani-inc/kms/v2/log"
)

// Setup our various connections and services
func Setup() {
	// Replace _ with ctx to uncomment the below examples
	log, _ := log.FromContext(context.Background(), "services")
	log.Info("setting up services...")

	// Uncomment to enable database support
	// database.Setup(ctx)

	// Connect to `kms-countries` for example
	// setupCountries(ctx)
}
