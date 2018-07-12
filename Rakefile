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
        if record.nil?
          auth.update(valid: false)
          auth.save
          next
        end
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

    # map.csv: SELECT string_2 as bib_number, accession_id, resource_id FROM user_defined WHERE string_2 IS NOT NULL;
    # bundle exec rake authorizer:authorities:as_sql
    desc 'Generate ArchivesSpace SQL from summary CSV'
    task :as_sql do
      raise "Summary CSV required!" unless File.file? 'authorizer.csv'
      raise "Map CSV required!"     unless File.file? 'map.csv'
      map = {
        accessions: {},
        resources: {},
      }
      CSV.foreach('map.csv', headers: true) do |row|
        data = row.to_hash
        if data["accession_id"] != "NULL"
          map[:accessions][data["bib_number"]] = data["accession_id"]
        elsif data["resource_id"] != "NULL"
          map[:resources][data["bib_number"]] = data["resource_id"]
        else
          raise "Irregular map entry: #{data.inspect}"
        end
      end

      sql_a = File.open('authorizer_accession.sql', 'w')
      sql_r = File.open('authorizer_resource.sql', 'w')
      CSV.foreach('authorizer.csv', headers: true) do |row|
        data       = row.to_hash
        ['accession', 'resource'].each do |t|
          template = File.read(File.join("templates", "#{t}_#{data["type"]}.erb")).gsub("\n", ' ')
          renderer = ERB.new(template)

          if t == 'accession' and map[:accessions].key?(data["bib_number"])
            data["linked_record_id"] = map[:accessions][data["bib_number"]]
            sql_a.puts(renderer.result(binding))
          end

          if t == 'resource' and map[:resources].key?(data["bib_number"])
            data["linked_record_id"] = map[:resources][data["bib_number"]]
            sql_r.puts(renderer.result(binding))
          end
        end
      end
      sql_a.close
      sql_r.close
    end

    # bundle exec rake authorizer:authorities:as_koch_sql
    desc 'Generate ArchivesSpace SQL from summary CSV for Koch Collection'
    task :as_koch_sql do
      raise "Summary CSV required!" unless File.file? 'authorizer.csv'
      sql = File.open('koch.sql', 'w')
      count = 0
      CSV.foreach('authorizer.csv', headers: true) do |row|
        data       = row.to_hash
        next unless data["bib_number"] == "8273828"
        template = File.read(File.join("templates", "koch_#{data["type"]}.erb")).gsub("\n", ' ')
        renderer = ERB.new(template)
        sql.puts renderer.result(binding)
        count +=1
      end
      sql.close
      puts "KOCH records: #{count}"
    end

    # bundle exec rake authorizer:authorities:summary
    desc 'Create authorizer summary csv'
    task :summary do
      attributes = %w{bib_number tag datafield identifier uri type agent_type agent_role}
      # IDEALLY THIS WOULD BE PUSHED TO RECORD PROCESSOR AND IN DB
      agent_type_map = {
        '100' => 'person',
        '110' => 'corporate_entity',
        '111' => 'corporate_entity',
        '600' => 'person',
        '610' => 'corporate_entity',
        '611' => 'corporate_entity',
        '692' => 'person',
        '693' => 'corporate_entity',
        '700' => 'person',
        '710' => 'corporate_entity',
        '711' => 'corporate_entity',
      }

      data = []
      puts "Collecting data for CSV\t#{Time.now}"
      Bib.order(:id).each_page(100) do |batch|
        current_page = batch.current_page.to_s
        puts "Generating summary:\t#{current_page}"
        batch.all.each do |bib|
          bib.auths_dataset.select(:tag, :datafield, :type, :source, :identifier, :uri).each do |auth|
            # next if auth.source == 'aat' # TODO: for now skip aat
            atype = agent_type_map.fetch(auth.tag, '')
            atype = 'family' if auth.datafield =~ /[167]00 3[0 ] \$a/

            row_data = { bib_number: bib.bib_number }
            row_data[:tag]        = auth.tag
            row_data[:datafield]  = auth.datafield
            # loc identifier is uri in aspace
            row_data[:identifier] = (auth.source == 'loc' or auth.source == 'aat') ? auth.uri : auth.identifier
            row_data[:uri]        = auth.uri
            row_data[:type]       = auth.type == 'name' ? 'agent' : 'subject'
            row_data[:agent_type] = atype
            row_data[:agent_role] = auth.tag =~ /^[1|7]/  ? 'creator' : 'subject'
            data << row_data
          end
        end
      end
      puts "Generating CSV\t#{Time.now}"
      csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        data.each do |row|
          csv << attributes.map{ |attr| row[attr.to_sym] }
        end
      end
      puts "Writing CSV to authorizer.csv\t#{Time.now}"
      File.open('authorizer.csv', 'w') { |f| f.write csv }
    end

    # bundle exec rake authorizer:authorities:undifferentiated
    desc 'Find undifferentiated LOC auth record headings'
    task :undifferentiated do
      Auth.select(:record).where(source: 'loc')
        .exclude(record: nil)
        .each_page(100) do |batch|
          batch.each do |b|
            record = b[:record]
            reader = MARC::XMLReader.new(StringIO.new(record))
            for r in reader
              puts r['001'] if r['667'] and r['667'].value =~ /^(?!formerly).*undifferentiated/i
            end
          end
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

    # bundle exec rake authorizer:authorities:update_identifier_to_uri
    desc 'Update 001 identifier to uri'
    task :update_identifier_to_uri do
      puts "Updating identifier to uri: #{Time.now}"
      Auth.select(:id, :uri).where(source: 'loc')
      .exclude(record: nil)
      .exclude(uri: nil).each_page(100) do |batch|
        logger.debug "Updating to uri for batch: #{batch.inspect}"
        batch.each do |b|
          auth   = Auth[b[:id]]
          record = MARC::XMLReader.new(StringIO.new(auth[:record])).first
          next if record.nil?
          record['001'].value = b[:uri]
          auth[:record] = record.to_xml
          auth.save
        end
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
      seen_cnt  = 0
      FileUtils.mkdir_p base_path
      Auth.where(source: source)
        .exclude(record: nil)
        .select(:uri, :identifier, :record)
        .each_page(1000) do |batch|
          current_page = batch.current_page.to_s
          puts "Dumping batch:\t#{current_page}"
          batch.all.each do |auth|
            path = File.join(base_path)
            FileUtils.mkdir_p path
            id = auth[:identifier] ? auth[:identifier] : URI.parse(auth[:uri]).path.split('/').last
            if seen.include? id
              seen_cnt +=1
              next
            end
            File.open(File.join(path, "#{id}.xml"), 'w') { |f| f.write auth[:record] }
            seen << id
          end
      end
      puts "Duplicate record count: #{seen_cnt}"
    end

    # TODO: rake authorizer:db:sweep (remove auths not associated with anything)

    # bundle exec rake authorizer:db:generate_aat_records
    desc 'Create aat records'
    task :generate_aat_records do
      Auth.where(source: 'aat')
        .each_page(1000) do |batch|
          current_page = batch.current_page.to_s
          puts "Processing batch:\t#{current_page}"
          batch.all.each do |auth|
            m        = MARC::Record.new
            m.leader = "00000nz  a2200000oi 4500"
            # pos 11 = r for aat
            m_008    = "860211|| anrnnbab|          |a ana |||"
            m << MARC::ControlField.new('001', auth.uri)
            m << MARC::ControlField.new('008', m_008)

            df   = auth.datafield
            tag  = df[0..2]
            inds = df[4..5]
            subs = df[7..-1]
            subs = subs.split('$').delete_if(&:empty?).map do |s|
              [ s[0..1].strip, s[2..-1].strip ]
            end
            m << MARC::DataField.new(tag, inds[0], inds[1], *subs)
            scope_content = Nokogiri::XML(auth.record).xpath("//Note_Text").first
            scope_content = Nokogiri::XML(auth.record).xpath("//*[@tag='680']").first unless scope_content
            m << MARC::DataField.new('680', ' ', ' ', ['i', scope_content.inner_text]) if scope_content
            auth.record = m.to_xml.to_s
            auth.save
        end
      end
    end

    # bundle exec rake authorizer:db:generate_stub_records
    desc 'Create stub records for auths without a uri'
    task :generate_stub_records do
      Auth.where(uri: nil)
        .each_page(1000) do |batch|
          current_page = batch.current_page.to_s
          puts "Processing batch:\t#{current_page}"
          batch.all.each do |auth|
            # id on the heading so we don't duplicate on import
            heading  = (auth.tag + auth.heading).strip.downcase # but include tag scope
            fake_id  = "dts_#{Digest::SHA1.hexdigest(heading)}"
            m        = MARC::Record.new
            m.leader = "00000nz  a2200000oi 4500"
            m << MARC::ControlField.new('001', fake_id)

            df   = auth.datafield
            tag  = df[0..2]
            inds = df[4..5]
            subs = df[7..-1]
            subs = subs.split('$').delete_if(&:empty?).map do |s|
              [ s[0..1].strip, s[2..-1].strip ]
            end
            m << MARC::DataField.new(tag, inds[0], inds[1], *subs)
            auth.identifier = fake_id
            auth.record     = m.to_xml.to_s
            auth.source     = 'dts'
            auth.save
        end
      end
    end

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

    # bundle exec rake authorizer:db:search_in_file[9451869]
    desc 'Search headings from mrc in file by bib number'
    task :search_in_file, [:bib, :file] do |_t, args|
      bib  = args[:bib]
      file = args[:file] || 'data/bib/authorizer.mrc'
      MARC::FileReader.new(file, :mrc).each_record do |record, count|
        if record['001'].value == bib
          puts record.to_s
          break
        end
      end
    end
  end
end
