require 'httparty'

# Lookup and download authority records from LOC
module LOCAuthority
  include HTTParty
  base_uri 'id.loc.gov'
  disable_rails_query_string_format

  def self.search(term, scheme, type)
    headers = { 'Accept' => 'text/xml' }
    query = {
      q: ["aLabel:\"#{term}\"", scheme, type],
      format: 'atom'
    }
    puts query
    response = get('/search/', headers: headers, query: query)
    response.body
  end

  # download and search for LOC name authorities
  class Name
    TYPE   = 'rdftype:Authority'.freeze
    SCHEME = 'cs:http://id.loc.gov/authorities/names'.freeze
    def self.search(term)
      LOCAuthority.search(term, SCHEME, TYPE)
    end
  end

  # download and search for LOC subject authorities
  class Subject
    TYPE   = 'rdftype:Authority'.freeze
    SCHEME = 'cs:http://id.loc.gov/authorities/subjects'.freeze
    def self.search(term)
      LOCAuthority.search(term, SCHEME, TYPE)
    end
  end
end
