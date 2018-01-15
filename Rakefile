#!/usr/bin/env ruby
require_relative 'authorizer'

namespace :authorizer do
  # logger for rake tasks
  logger = Logging.logger(STDOUT)
  logger.add_appenders([Logging.appenders.file(LOG_FILE)])

  # bundle exec rake authorizer:report
  desc 'DB report'
  task :report do
    report = {}
    report[:total_bibs]           = Bib.count
    report[:total_auths]          = Auth.count
    report[:auths_with_0]         = Auth.where(ils: 1).count
    report[:auths_from_loc]       = Auth.where(ils: 1, source: 'loc').count
    report[:auths_from_loc_dl]    = Auth.where(ils: 1, source: 'loc').exclude(record: nil).count
    report[:auths_from_loc_valid] = Auth.where(ils: 1, source: 'loc', valid: true).exclude(record: nil).count
    report[:auths_from_aat]       = Auth.where(ils: 1, source: 'aat').count
    report[:auths_from_aat_dl]    = Auth.where(ils: 1, source: 'aat').exclude(record: nil).count
    report[:auths_from_other]     = Auth.where(ils: 1).exclude(source: 'loc').exclude(source: 'aat').count

    puts JSON.pretty_generate report
  end

  namespace :authorities do
    namespace :download do
      # bundle exec rake authorizer:authorities:download:batch
      desc 'Download all db authority records'
      task :batch do |_t, args|
        puts "Downloading authority records: #{Time.now}"
        loop do
          Auth.where(record: nil).exclude(uri: nil).exclude(source: nil).each_page(100) do |batch|
            logger.debug "Downloading batch: #{batch.inspect}"
            Parallel.each(batch.all, in_threads: 4) do |auth|
              # don't process unrecognized source
              next unless auth.source == 'loc' or auth.source == 'aat'
              uri = auth.uri
              begin
                result = auth.source == 'loc' ? LOCDownload.get(uri) : AATDownload.get(uri)
                auth.record = result
                auth.save
              rescue Exception => ex
                logger.error "Failed to download and save: #{uri}"
              end
            end
          end
          puts "Batch processed, use [Ctrl-c] to exit or resume in 5s: #{Time.now}"
          sleep 5
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

    # bundle exec rake authorizer:authorities:validate_loc_heading[1]
    desc 'Validate that LOC auth record heading matches authorized form'
    task :validate_loc_heading, [:id] do |_t, args|
      id = args[:id].to_i || nil
      raise "Auth record id required" unless id
      auth   = Auth[id]
      if auth.source == 'loc'
        record = MARC::XMLReader.new(StringIO.new(auth[:record])).first
        regexp               = auth[:type] == 'name' ? /,http.*/ : /(--|http.*)/
        # fingerprint (heading w/o delims, uri & non-word chars)
        unauthorized_heading = auth[:heading].gsub(regexp, '').gsub(/[^[:word:]]+/, '')
        authorized_heading   = record.find_all {|f| f.tag =~ /^1../}.first.value.gsub(/[^[:word:]]+/, '')
        if unauthorized_heading.unicode_normalize == authorized_heading.unicode_normalize
          auth.update(valid: true)
        else
          auth.update(valid: false)
          puts "Invalid heading for #{auth[:uri]}: \"#{unauthorized_heading}\" vs. \"#{authorized_heading}\""
        end
        auth.save
      end
    end

    # bundle exec rake authorizer:authorities:validate_loc_headings
    desc 'Validate all LOC auth record headings'
    task :validate_loc_headings do
      loop do
        puts "Validating LOC headings: #{Time.now}"
        Auth.select(:id).where(source: 'loc')
          .exclude(record: nil)
          .exclude(valid: true)
          .each_page(100) do |batch|
            ids = batch.map { |b| b.id }
            logger.debug "Validating batch: #{batch.inspect}"
            Parallel.each(ids, in_threads: 4) do |id|
              Rake::Task['authorizer:authorities:validate_loc_heading'].invoke(id)
              Rake::Task['authorizer:authorities:validate_loc_heading'].reenable
            end
        end
        puts "Group processed, use [Ctrl-c] to exit or resume in 5s: #{Time.now}"
        sleep 5
      end
    end
  end

  namespace :bib do
    # bundle exec rake authorizer:bib:print[123456]
    desc 'Print marc record as xml to console'
    task :print, [:bib_number] do |_t, args|
      bib_number = args[:bib_number] || nil
      raise "Bib no. required!" unless bib_number
      bib = Bib.where(bib_number: bib_number).first
      puts bib.inspect
    end
  end

  namespace :db do
    # bundle exec rake authorizer:db:dump_auth_xml
    desc 'Dump authority records to data/auth'
    task :dump_auth_xml, [:source] do |_t, args|
      source    = args[:source] || 'loc'
      base_path = File.join("data", "auth", source)
      # use to avoid writing same record multiple times (needed if add parallel)
      seen      = Set.new
      FileUtils.mkdir_p base_path
      Auth.where(source: source)
        .exclude(uri: nil)
        .exclude(record: nil)
        .select(:uri, :identifier, :record)
        .each_page(1000) do |batch|
          current_page = batch.current_page.to_s
          puts "Dumping batch:\t#{current_page}"
          batch.all.each do |auth|
            path = File.join(base_path, current_page)
            FileUtils.mkdir_p path
            id = auth[:identifier] ? auth[:identifier] : URI.parse(auth[:uri]).path.split('/').last
            next if seen.include? id
            File.open(File.join(path, "#{id}.xml"), 'w') { |f| f.write auth[:record] }
            seen << id
          end
      end
    end

    # TODO: rake authorizer:db:sweep (remove auths not associated with anything)

    # bundle exec rake authorizer:db:populate_from_dir
    desc 'Add headings from mrc in directory to database'
    task :populate_from_dir, [:directory] do |_t, args|
      directory = args[:directory] || 'data/bib'
      # TODO: check directory
      total = 0
      MARC::DirectoryReader.new(directory, :xml).each_record do |record, count|
        Rake::Task['authorizer:db:process_record'].invoke(record)
        Rake::Task['authorizer:db:process_record'].reenable
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
