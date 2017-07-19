class Auth < Sequel::Model
  many_to_many :bibs
end
