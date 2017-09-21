require 'marc'

module MARC
  # read each bib in file and yield record
  class FileReader
    attr_reader :bib_file, :reader

    def initialize(file, reader = :xml)
      @bib_file = file
      @logger   = Logging.logger[self]
      @reader   = reader == :xml ? MARC::XMLReader : MARC::Reader
    end

    def each_record
      count = 0
      @logger.debug "Reading bib: #{bib_file}"
      reader.new(bib_file, external_encoding: 'UTF-8').each do |record|
        count += 1
        yield record, count
      end
    end
    alias each each_record
  end
end
