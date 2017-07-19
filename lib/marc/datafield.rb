module MARC

  class DataField
    def to_query_str(joiner = '--')
      subfields.map{ |s| s.value.strip.gsub(/\.$/, '') }.join(joiner).squeeze(',')
    end
  end

end