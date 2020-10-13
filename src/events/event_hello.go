package events

import (
	"context"
	"math/rand"
	"time"

	"github.com/kyani-inc/kms/v2/log"
	"github.com/kyani-inc/kms/v2/worker"
	pb "github.com/kyani-inc/proto/example"
)

// PersonSaidHello handles the event from SQS
func PersonSaidHello(ctx context.Context, e *worker.Event) error {
	// Generate a scoped logger for this method
	log, ctx := log.FromContext(ctx)

	// Bind event type from our Subscribe
	event := &pb.EventPersonSaidHello{}
	if err := e.Bind(event); err != nil {
		log.Errorf("received invalid/unexpected event: %v", err)
		return err // retry
	}

	log.Infof("%s said hello and replied with: %s", event.GetPerson(), event.GetReply())
	time.Sleep(time.Duration(rand.Intn(5)+3) * 100 * time.Millisecond)

	// Acknowledge the message to remove it from the queue
	return e.Acknowledge(ctx)
}
