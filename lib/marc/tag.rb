require 'marc'

module MARC
  module Tag
    # MARC::Tag::NAMES
    NAMES = %w[
      100
      110
      111
      600
      610
      611
    ].freeze

    # MARC::Tag::SUBJECTS
    SUBJECTS = %w[
      650
      651
      655
    ].freeze

    # MARC::Tag::AUTHS
    AUTHS = (NAMES + SUBJECTS).freeze
  end
end
