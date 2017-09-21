require 'marc'

module MARC
  # read each bib in directory and yield record
  class DirectoryReader
    attr_reader :directory, :reader

    def initialize(directory, reader = :xml)
      @directory = directory
      @logger    = Logging.logger[self]
      @reader    = reader == :xml ? MARC::XMLReader : MARC::Reader
    end

    def each_record
      count = 0
      Dir[File.join(directory, '*.xml')].each do |bib_file|
        @logger.debug "Reading bib: #{bib_file}"
        reader.new(bib_file, external_encoding: 'UTF-8').each do |record|
          count += 1
          yield record, count
        end
      end
    end
    alias each each_record
  end
end
