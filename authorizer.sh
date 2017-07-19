#!/bin/bash

bundle exec sequel -m db/migrations \
  -M 0 \
  "mysql2://127.0.0.1/authorizer?user=authorizer&password=authorizer"

bundle exec sequel -m db/migrations \
  "mysql2://127.0.0.1/authorizer?user=authorizer&password=authorizer"

rake authorizer:db:populate
rake authorizer:authorities:lookup
