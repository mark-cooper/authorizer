#!/usr/bin/env ruby
require 'logging'
require_relative 'lib/loc/authority'
require_relative 'lib/marc/directory_reader'

LOG_FILE = 'authorizer.log'
Logging.logger.root.add_appenders([
  Logging.appenders.stdout,
  Logging.appenders.file(LOG_FILE)
])
Logging.logger.root.level = :debug

namespace :authorizer do
  # logger for rake tasks
  logger = Logging.logger(STDOUT)
  logger.add_appenders([Logging.appenders.file(LOG_FILE)])

  namespace :authorities do
    desc 'Download authority records'
    task :download, [:directory] do |_t, args|
      directory = args[:directory] || 'data/bib'
      # TODO: check directory
      # TODO: use auth records with uri in db
      puts directory
    end

    # rake authorizer:authorities:lookup
    desc 'Lookup authorities'
    task :lookup, [:directory] do |_t, args|
      # TODO: lookup auth records w/o uri / identifier
    end

    # rake authorizer:authorities:search_name['Obama\, Barack']
    desc 'Search for a subject authority record'
    task :search_name, [:term] do |_t, args|
      puts LOCAuthority::Name.search(args[:term])
    end

    # rake authorizer:authorities:search_subject['Cyberpunk fiction']
    desc 'Search for a subject authority record'
    task :search_subject, [:term] do |_t, args|
      puts LOCAuthority::Subject.search(args[:term])
    end
  end

  namespace :db do
    # rake authorizer:db:populate
    desc 'Add headings from mrc to database'
    task :populate, [:directory] do |_t, args|
      directory = args[:directory] || 'data/bib'
      # TODO: check directory
      count = 0
      MARC::DirectoryReader.new(directory, :xml).each_record do |record|
        record['245']['a']
        # TODO: lookup heading, add to db
        count += 1
      end
      logger.debug "Bib records read: #{count}"
    end
  end
end
