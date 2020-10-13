package rpc

import (
	"github.com/kyani-inc/kms-example/src/rpc/example"
	"google.golang.org/grpc"
)

func Setup(server *grpc.Server) {
	// Setup services
	example.Register(server)
}
