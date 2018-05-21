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
