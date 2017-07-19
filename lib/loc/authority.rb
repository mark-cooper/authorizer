require 'httparty'

# Lookup and download authority records from LOC
module LOCAuthority
  include HTTParty
  base_uri 'id.loc.gov'
  disable_rails_query_string_format

  SEARCH_PATH    = '/search/'.freeze
  SEARCH_HEADERS = { 'Accept' => 'text/xml' }.freeze

  def self.search(term, scheme, type)
    query = {
      q: ["aLabel:\"#{term}\"", scheme, type],
      format: 'atom'
    }
    response = get(SEARCH_PATH, headers: SEARCH_HEADERS, query: query)
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
