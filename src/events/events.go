package events

import (
	"github.com/kyani-inc/kms/v2/worker"
	"github.com/kyani-inc/proto/example"
)

// Store Worker instance for publishing events
var Worker *worker.Worker

// Setup the worker and handlers
func Setup() *worker.Worker {
	// Setup KMS worker instance used for
	// subscribing to and publishing events
	cfg := worker.DefaultConfig()
	w := worker.New(cfg)

	// Messages throughput (messages per second) is calculated as:
	//   MaxWorkers * Number of ECS Tasks * Execution time of each worker

	// Bindings
	// NOTE: be sure to add these events to the SNS subscription filter
	// policy to ensure this service's queue isn't receiving *every* event
	w.Subscribe(&example.EventPersonSaidHello{}, PersonSaidHello)

	Worker = w
	return w
}
