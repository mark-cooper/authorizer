require 'nokogiri'
require 'open-uri'

module LOCDownload

  def self.get(uri, format = 'marcxml.xml')
    Nokogiri::XML(open("#{uri}.#{format}")) { |x| x.noblanks }.to_xml(save_with:  0)
  end

end
