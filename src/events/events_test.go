package events_test

import (
	"context"
	"log"
	"testing"

	"github.com/kyani-inc/kms/v2/worker"
	"github.com/kyani-inc/proto/example"
	"github.com/stretchr/testify/assert"
	"github.com/subosito/gotenv"
)

func TestMain(m *testing.M) {
	// load env vars from file if available
	if err := gotenv.Load("../../env"); err != nil {
		log.Fatalf("could not load env file, file not found: %s", err.Error())
	}
}

// TestPublishEventSyncReps the worker and handlers
func TestPublishEventSyncReps(t *testing.T) {
	// Setup KMS worker instance used for
	// subscribing to and publishing events
	w := worker.New(worker.DefaultConfig())

	messageID, err := w.Publish(context.Background(), &example.EventPersonSaidHello{
		Person: &example.Person{
			Name: "Test Suite",
		},
		Reply: "This was a reply message",
	})
	assert.Nil(t, err, "error publishing message: %s", err)
	assert.NotEmpty(t, messageID)
}
