module Authorizer
  # Idempotent support class for processing marc records
  # into authorizer bib / auth models
  class RecordProcessor
    attr_reader :record, :name_tags, :subject_tags, :auth_tags, :datafields

    # Authorizer::RecordProcessor.new(record)
    def initialize(record, name_tags = [], subject_tags = [])
      @record       = record
      @name_tags    = name_tags
      @subject_tags = subject_tags
      @auth_tags    = (name_tags + subject_tags).freeze
      @datafields   = []
      @logger       = Logging.logger[self]
    end

    def process
      bib_number = record['001'].value
      title      = record['245'].value
      bib_record = get_or_create_bib(bib_number, title)

      record.each_by_tag(auth_tags) do |auth|
        type       = name_tags.include?(auth.tag) ? 'name' : 'subject'
        heading    = type == 'name' ? auth.to_query_str(',') : auth.to_query_str
        source     = auth['2']
        uri        = auth['0']
        uri        = uri.strip if uri
        identifier = uri ? URI.parse(uri).path.split('/').last : nil
        ils        = uri ? true : false

        # update source if not set but we have uri and matches loc
        source  = 'loc' if !source and uri =~ /id\.loc\.gov/
        source  = 'loc' if source and source == 'lcsh' # late addition

        data = {
          tag: auth.tag,
          datafield: auth.to_s,
          heading: heading,
          type: type,
          source: source,
          uri: uri,
          identifier: identifier,
          ils: ils
        }
        datafields << data[:datafield]
        get_or_create_auth_for(bib_record, data)
      end
      remove_unused_auths_for(bib_record)
      bib_record
    end

    # PROCESS RELATED METHODS

    def get_or_create_auth_for(bib_record, data)
      auth_record = Auth.where(datafield: data[:datafield]).first
      if auth_record
        bib_has_auth = bib_record.auths.find do |a|
          a[:datafield] == auth_record[:datafield]
        end
        bib_record.add_auth auth_record unless bib_has_auth
        uri = data[:uri]
        if uri && auth_record.uri != uri
          auth_record.uri        = uri
          auth_record.identifier = data[:identifier]
          auth_record.save
          @logger.debug("Updated uri for datafield #{data[:datafield]}")
        end
      else
        auth_record = Auth.new(data).save
        bib_record.add_auth auth_record
        @logger.debug("Created auth with datafield: #{data[:datafield]}")
      end
      auth_record
    end

    def get_or_create_bib(bib_number, title)
      bib_record = Bib.where(bib_number: bib_number).first
      unless bib_record
        bib_record = Bib.new(
          bib_number: bib_number,
          title:      title,
        ).save
        @logger.debug("Created bib with number: #{bib_number}")
      end
      bib_record
    end

    def remove_unused_auths_for(bib_record)
      # remove any auths not in datafields ('cus record was updated)
      bib_record.auths.each do |auth|
        unless datafields.include?(auth[:datafield])
          @logger.debug("Removing unused authority for #{bib_record.id}: #{auth.inspect}")
          auth.remove_bib bib_record
        end
      end
    end
  end
end
