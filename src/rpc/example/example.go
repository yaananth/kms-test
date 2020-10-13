package example

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/kyani-inc/kms-example/src/app/example"
	"github.com/kyani-inc/kms/v2"
	pbc "github.com/kyani-inc/proto/countries"
	pb "github.com/kyani-inc/proto/example"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// Server implements the HelloServiceServer interface
// inheriting from protobuf unimplemented methods
type Server struct {
	pb.UnimplementedHelloServiceServer
}

// SayHello says hello!
func (Server) SayHello(ctx context.Context, req *pb.SayHelloRequest) (*pb.SayHelloResponse, error) {
	resp := &pb.SayHelloResponse{}

	// Say hello using proto service
	answer, err := example.SayHello(ctx, req.GetPerson())
	if err != nil {
		return nil, status.Errorf(codes.Unknown, "error saying hello: %v", err)
	}

	// Call countries to test xray service map
	{
		connectCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		defer cancel()

		conn, err := kms.ConnectRPC(connectCtx, "countries", os.Getenv("KMS_ENV"), grpc.WithBlock())
		if err != nil {
			return nil, err
		}
		defer conn.Close()

		client := pbc.NewCountryServiceClient(conn)
		resp, err := client.Get(ctx, &pbc.CountryRequest{
			Query: &pbc.CountryRequest_Code{
				Code: "ca",
			},
		})
		if err != nil {
			return nil, err
		}

		fmt.Printf("country: %#v\n", resp.GetCountry())
	}

	// Return
	resp.Response = answer
	return resp, nil
}

// Register connects the service to the listener
func Register(server *grpc.Server) {
	pb.RegisterHelloServiceServer(server, &Server{})
}
