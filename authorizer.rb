require 'logging'
require 'pry'
require 'sequel'

# TODO: config file
Sequel::Model.db = Sequel.connect('sqlite://db/authorizer.db')

LOG_FILE = 'authorizer.log'.freeze
Logging.logger.root.add_appenders([
  Logging.appenders.stdout,
  Logging.appenders.file(LOG_FILE)
])
Logging.logger.root.level = :debug

require_relative 'app/models/auth'
require_relative 'app/models/bib'
require_relative 'lib/loc/authority'
require_relative 'lib/marc/datafield'
require_relative 'lib/marc/directory_reader'
require_relative 'lib/marc/file_reader'
require_relative 'lib/marc/tag'

