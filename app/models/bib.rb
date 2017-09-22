class Bib < Sequel::Model(:bibs)
  many_to_many :auths
end
