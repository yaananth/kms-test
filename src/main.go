package main

import (
	"github.com/kyani-inc/kms-example/src/events"
	"github.com/kyani-inc/kms-example/src/rest"
	"github.com/kyani-inc/kms-example/src/rpc"
	"github.com/kyani-inc/kms-example/src/services"
	"github.com/kyani-inc/kms/v2"
)

func main() {
	// Create KMS service & bind handlers
	server := kms.NewService(kms.ServiceName("example"))
	server.EnableRPC(rpc.Setup)
	server.EnableREST(rest.Setup)
	server.EnableWorker(events.Setup)

	// Do our app-specific setup/initialization here
	services.Setup()

	// Start the server
	server.Start()
}
