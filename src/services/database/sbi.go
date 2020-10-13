package database

import (
	"context"
	"os"
	"strconv"

	"github.com/kyani-inc/kms/v2"
	"github.com/kyani-inc/kms/v2/log"
	"github.com/kyani-inc/kms/v2/providers/gormdb"
)

func setupSBI(ctx context.Context) {
	// Generate a scoped logger for this method
	log, ctx := log.FromContext(ctx, "setupSBI")

	def := func(a string, d int) int {
		if a == "" {
			return d
		}

		i, err := strconv.Atoi(a)
		if err != nil {
			log.Warnw("unable to convert env var", "os env", a, "use", d, "error", err.Error())
			return d
		}
		return i
	}

	// Setup DB
	kms.RegisterDatabaseProvider("sbiDB", gormdb.New())
	db := kms.NewDatabase("sbiDB")
	db.SetDriver("mysql")

	masterConfig, err := kms.NewIAMAuthenticatedDatabase(os.Getenv("DB_SBI__MASTER__DSN"), nil)
	if err != nil {
		log.Fatalw("error upgrading master DSN to IAM", "error", err.Error())
	}

	replicaConfig, err := kms.NewIAMAuthenticatedDatabase(os.Getenv("DB_SBI__REPLICA__DSN"), nil)
	if err != nil {
		log.Fatalw("error upgrading replica DSN to IAM", "error", err.Error())
	}

	db.SetMasterLogging(os.Getenv("DB_SBI__LOGGING") == "on")
	db.SetMasterDSN(masterConfig)
	db.SetMasterPool(def(os.Getenv("DB_SBI__MASTER__IDLE"), 1), def(os.Getenv("DB_SBI__MASTER__MAX"), 10))

	db.SetReplicaLogging(os.Getenv("DB_SBI__LOGGING") == "on")
	db.SetReplicaDSN(replicaConfig)
	db.SetReplicaPool(def(os.Getenv("DB_SBI__REPLICA__IDLE"), 1), def(os.Getenv("DB_SBI__REPLICA__MAX"), 10))

	// Fail out right now if we can't connect
	masterErr, replicaErr := db.Ping()
	if masterErr != nil {
		log.Fatalw("error connecting to master SBI database", "error", masterErr.Error())
	}
	if replicaErr != nil {
		log.Fatalw("error connecting to replica SBI database", "error", replicaErr.Error())
	}

	SBI = db
}
