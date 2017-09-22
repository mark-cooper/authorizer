#!/usr/bin/env ruby
require 'logging'
require 'sequel'

# TODO: config file
Sequel::Model.db = Sequel.connect('sqlite://db/authorizer.db')

require_relative 'app/models/auth'
require_relative 'app/models/bib'
require_relative 'lib/loc/authority'
require_relative 'lib/marc/datafield'
require_relative 'lib/marc/directory_reader'
require_relative 'lib/marc/file_reader'
require_relative 'lib/marc/tag'

LOG_FILE = 'authorizer.log'.freeze
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
      directory = args[:directory] || 'data/auth'
      # TODO: check directory
      # TODO: use auth records with uri in db
      puts directory
    end

    # rake authorizer:authorities:lookup
    desc 'Lookup authorities'
    task :lookup do |_t, args|
      # TODO: Getty AAT
      Auth.where(uri: nil).each do |auth|
        next if auth[:source] == 'aat'
        searcher = auth[:type] == 'subject' ? LOCAuthority::Subject : LOCAuthority::Name
        query_uri = searcher.search(auth[:heading], true)
        if query_uri != auth.query
          begin
            # updated query means not queried (via authorizer) yet!
            logger.debug "Setting query for \"#{auth[:heading]}\" to \"#{query_uri}\""
            auth.query   = query_uri
            auth.matches = nil
            auth.save
          rescue Sequel::DatabaseError => ex
            logger.error ex.message
          end
        end
        # TODO: lookup auth records w/o uri / identifier if matches nil
      end
    end

    # rake authorizer:authorities:search_name['Obama\, Barack']
    # rake authorizer:authorities:search_name['Bishop\, Elizabeth\,1911-1979']
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
    # TODO: rake authorizer:db:sweep (remove auths not associated with anything)

    # rake authorizer:db:populate_from_dir
    desc 'Add headings from mrc in directory to database'
    task :populate_from_dir, [:directory] do |_t, args|
      directory = args[:directory] || 'data/bib'
      # TODO: check directory
      total = 0
      MARC::DirectoryReader.new(directory, :xml).each_record do |record, count|
        Rake::Task['db:process_record'].invoke(record)
        Rake::Task['db:process_record'].reenable
        total = count
      end
      logger.debug "Bib records read: #{total}"
    end

    # rake authorizer:db:populate_from_file
    desc 'Add headings from mrc in file to database'
    task :populate_from_file, [:file] do |_t, args|
      file = args[:file] || 'data/bib/authorizer.mrc'
      # TODO: check file
      total = 0
      MARC::FileReader.new(file, :mrc).each_record do |record, count|
        Rake::Task['authorizer:db:process_record'].invoke(record)
        Rake::Task['authorizer:db:process_record'].reenable
        total = count
      end
      logger.debug "Bib records read: #{total}"
    end

    desc 'Process marc into bib and auth records'
    task :process_record, [:record] do |_t, args|
      record     = args[:record]
      bib_number = record['001'].value
      bib_record = Bib.where(bib_number: bib_number).first
      datafields = []
      unless bib_record
        bib_record = Bib.new(bib_number: bib_number).save
        logger.debug("Created bib with number: #{bib_number}")
      end

      # TODO: memberOf for search
      record.each_by_tag(MARC::Tag::AUTHS) do |auth|
        type    = MARC::Tag::NAMES.include?(auth.tag) ? 'name' : 'subject'
        heading = type == 'name' ? auth.to_query_str(',') : auth.to_query_str
        source  = auth['2']
        uri     = auth['0']
        ils     = uri ? true : false

        data = {
          tag: auth.tag,
          datafield: auth.to_s,
          heading: heading,
          type: type,
          source: source,
          uri: uri,
          ils: ils
        }
        datafields << data[:datafield]

        auth_record = Auth.where(datafield: data[:datafield]).first
        if auth_record
          bib_has_auth = bib_record.auths.find do |a|
            a[:datafield] == auth_record[:datafield]
          end
          bib_record.add_auth auth_record unless bib_has_auth
          if uri && auth_record.uri != uri
            auth_record.uri = uri
            auth_record.save
            logger.debug("Updated uri for datafield #{data[:datafield]}")
          end
        else
          auth_record = Auth.new(data).save
          bib_record.add_auth auth_record
          logger.debug("Created auth with datafield: #{data[:datafield]}")
        end
      end

      # remove any auths not in datafields ('cus record was updated)
      bib_record.auths.each do |auth|
        unless datafields.include?(auth[:datafield])
          bib_record.remove_auth auth
        end
      end
    end
  end
end
