package main

import (
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws/credentials/stscreds"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/kyani-inc/kms/v2"
	"github.com/subosito/gotenv"
	"github.com/tjsage/simpleMigrate/migrate"
)

func main() {
	gotenv.Load("env")

	dsn := os.Getenv("DB_MIGRATE_DSN")
	if dsn == "" {
		panic("DB_MIGRATE_DSN not set")
	}

	// Set globally in Jenkins
	accountID := os.Getenv("AWS_ACCOUNT_ID")
	if accountID == "" {
		panic("AWS_ACCOUNT_ID not set")
	}

	// Set by migrate.sh
	kmsName := os.Getenv("KMS_NAME")
	if kmsName == "" {
		panic("KMS_NAME not set")
	}

	// Set by migrate.sh
	environment := os.Getenv("KMS_ENV")
	if environment == "" {
		panic("ENVIRONMENT not set")
	}

	// Build ARN role from environment
	arn := fmt.Sprintf("arn:aws:iam::%s:role/%s__%s", accountID, kmsName, environment)
	sess := session.Must(session.NewSession())
	sess.Config.Credentials = stscreds.NewCredentials(sess, arn)

	// Upgrade our DSN to use IAM authentication and the assumed role
	config, err := kms.NewIAMAuthenticatedDatabase(dsn, sess)
	if err != nil {
		panic(err.Error())
	}

	err = migrate.Migrate(config.DSN(), "./src/migrate/scripts")
	if err != nil {
		panic(err.Error())
	}
}
