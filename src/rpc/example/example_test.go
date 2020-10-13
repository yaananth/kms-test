package example_test

import (
	"context"
	"log"
	"os"
	"testing"
	"time"

	"github.com/kyani-inc/kms/v2"
	pb "github.com/kyani-inc/proto/example"
	"github.com/stretchr/testify/assert"
	"github.com/subosito/gotenv"
	"google.golang.org/grpc"
)

var client pb.HelloServiceClient

func TestMain(m *testing.M) {
	// Load env vars from file if available
	if err := gotenv.Load("../../../env"); err != nil {
		log.Printf("couldn't load environment file, error: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Connect to RPC
	conn, err := kms.ConnectRPC(ctx, kms.ServiceName("example"), os.Getenv("PORT"), grpc.WithBlock())
	if err != nil {
		log.Fatalf("error connecting to service: %s", err.Error())
	}
	defer conn.Close()

	// Create new client
	client = pb.NewHelloServiceClient(conn)
	os.Exit(m.Run())
}

func TestSayHello(t *testing.T) {
	resp, err := client.SayHello(context.Background(), &pb.SayHelloRequest{
		Person: &pb.Person{
			Name: "Test Suite",
		},
	})
	assert.Nil(t, err, "error saying hello: %v", err)
	assert.NotEmpty(t, resp.Response)
}
