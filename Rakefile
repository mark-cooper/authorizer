#!/usr/bin/env ruby
require_relative 'authorizer'

namespace :authorizer do
  # logger for rake tasks
  logger = Logging.logger(STDOUT)
  logger.add_appenders([Logging.appenders.file(LOG_FILE)])

  namespace :authorities do
    namespace :download do
      # bundle exec rake authorizer:authorities:download:batch
      desc 'Download all db authority records'
      task :batch do |_t, args|
        Auth.where(record: nil).exclude(uri: nil).each_page(100) do |batch|
          logger.debug "Downloading batch: #{batch.inspect}"
          Parallel.each(batch.all, in_processes: 4) do |auth|
            # don't process unrecognized source
            next unless auth.source.nil? or auth.source == 'aat'
            uri = auth.uri
            begin
              result = auth.source.nil? ? LOCDownload.get(uri) : AATDownload.get(uri)
              auth.record = result
              auth.save
            rescue Exception => ex
              logger.error "Failed to download and save: #{uri}"
            end
          end
        end
      end

      # bundle exec rake authorizer:authorities:download:debug[uri,LOC]
      desc 'Download debug authority record'
      task :debug, [:uri, :type] do |_t, args|
        uri    = args[:uri]
        type   = args[:type] || 'LOC'
        result = type == 'LOC' ? LOCDownload.get(uri) : AATDownload.get(uri)
        puts result
      end
    end

    # bundle exec rake authorizer:authorities:query_uri
    desc 'Set the query uri to use for auth record lookups'
    task :query_uri do |_t, args|
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
      end
    end

    # bundle exec rake authorizer:authorities:search_name['Obama\, Barack']
    # bundle exec rake authorizer:authorities:search_name['Bishop\, Elizabeth\,1911-1979']
    desc 'Search for a subject authority record'
    task :search_name, [:term] do |_t, args|
      puts LOCAuthority::Name.search(args[:term])
    end

    # bundle exec rake authorizer:authorities:search_subject['Cyberpunk fiction']
    desc 'Search for a subject authority record'
    task :search_subject, [:term] do |_t, args|
      puts LOCAuthority::Subject.search(args[:term])
    end
  end

  namespace :db do
    # TODO: rake authorizer:db:sweep (remove auths not associated with anything)

    # bundle exec rake authorizer:db:populate_from_dir
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

    # bundle exec rake authorizer:db:populate_from_file
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

    # bundle exec rake authorizer:db:process_record[record]
    desc 'Process marc into bib and auth records'
    task :process_record, [:record] do |_t, args|
      record    = args[:record]
      processor = Authorizer::RecordProcessor.new(
        record,
        MARC::Tag::NAMES,
        MARC::Tag::SUBJECTS
      )
      processor.process
    end
  end
end
