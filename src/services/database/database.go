package database

import (
	"context"

	"github.com/kyani-inc/kms/v2"
	"github.com/kyani-inc/kms/v2/log"
)

var (
	SBI kms.Database
)

func Setup(ctx context.Context) {
	_, ctx = log.FromContext(ctx, "database")

	setupSBI(ctx)
}
