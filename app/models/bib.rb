class Bib < Sequel::Model
  many_to_many :auths
end
