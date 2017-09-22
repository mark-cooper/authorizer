require 'nokogiri'
require 'open-uri'

module AATDownload

  BASE_URL = 'http://vocabsservices.getty.edu/AATService.asmx/AATGetSubject?subjectID='.freeze

  def self.get(uri)
    id = URI.parse(uri).path.split('/').last
    Nokogiri::XML(open("#{BASE_URL}#{id}")) { |x| x.noblanks }.to_xml(save_with:  0)
  end

end
