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
      692
      693
      700
      710
      711
    ].freeze

    # MARC::Tag::SUBJECTS
    SUBJECTS = %w[
      630
      650
      651
      655
      656
      690
      740
    ].freeze

    # MARC::Tag::AUTHS
    AUTHS = (NAMES + SUBJECTS).freeze
  end
end
