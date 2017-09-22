#!/bin/bash

bundle exec sequel -m db/migrations -M 0 'sqlite://db/authorizer.db'
bundle exec sequel -m db/migrations 'sqlite://db/authorizer.db'
bundle exec rake authorizer:db:populate_from_file

