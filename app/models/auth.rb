class Auth < Sequel::Model(:auths)
  many_to_many :bibs
end
