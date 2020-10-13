package main

import (
	"context"
	"fmt"
	"time"

	"github.com/kyani-inc/kms/v2"
	pb "github.com/kyani-inc/proto/example"
	"github.com/subosito/gotenv"
	"google.golang.org/grpc"
)

func main() {
	// Load env vars from file if available
	if err := gotenv.Load("env"); err != nil {
		panic("couldn't load environment file: " + err.Error())
	}

	// Timeout connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Connect to gRPC service
	// NOTE: pass WithBlock for testing where the connection needs to be
	// available immediately. Otherwise, connection happens in the background
	conn, err := kms.ConnectRPC(ctx, kms.ServiceName("example"), kms.ServiceEnvStaging, grpc.WithBlock())
	if err != nil {
		panic("error:" + err.Error())
	}
	defer conn.Close()

	// New client
	client := pb.NewHelloServiceClient(conn)

	// Say hi!
	// Use a fresh context here to not get timed out if this request is slow
	response, err := client.SayHello(context.Background(), &pb.SayHelloRequest{
		Person: &pb.Person{
			Name: "Test User",
		},
	})
	if err != nil {
		fmt.Printf("error saying hello: %v\n", err)
		return
	}

	fmt.Printf("said hello, got response: %s\n", response.GetResponse())
}
