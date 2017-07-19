#!/usr/bin/env ruby
require 'logging'
require_relative 'lib/loc/authority'
require_relative 'lib/marc/directory_reader'

logger_appenders = [
  Logging.appenders.stdout,
  Logging.appenders.file('authorizer.log')
]
Logging.logger.root.add_appenders(logger_appenders)
Logging.logger.root.level = :debug

# logger for rake tasks
logger = Logging.logger(STDOUT)
logger.add_appenders(logger_appenders)

# report: bibid, heading, match, identifier

namespace :authorizer do
  namespace :authorities do
    desc 'Download authority records'
    task :download, [:directory, :output] do |_t, args|
      directory = args[:directory] || 'data/bib'
      output    = args[:output]    || 'data/auth'
      # TODO: check directory
      puts directory
      puts output
    end

    # rake authorizer:authorities:lookup
    desc 'Lookup authorities'
    task :lookup, [:directory] do |_t, args|
      directory = args[:directory] || 'data/bib'
      # TODO: check directory
      count = 0
      MARC::DirectoryReader.new(directory, :xml).each_record do |record|
        record['245']['a']
        # TODO: lookup heading, write to csv
        count += 1
      end
      logger.debug "Bib records read: #{count}"
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
end
