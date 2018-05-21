#!/bin/bash

### RESET
echo "Deleting AAT records"
for file in ./data/auth/aat/*.xml; do rm "$file"; done
echo "Deleting DTS records"
for file in ./data/auth/dts/*.xml; do rm "$file"; done
echo "Deleting LOC records"
for file in ./data/auth/loc/*.xml; do rm "$file"; done

echo "Deleting csv, logs and sql"
> authorizer.log
rm -f *.csv *.sql

echo "Running database migrations"
bundle exec sequel -m db/migrations -M 0 'sqlite://db/authorizer.db'
bundle exec sequel -m db/migrations 'sqlite://db/authorizer.db'
bundle exec rake authorizer:db:populate_from_file
