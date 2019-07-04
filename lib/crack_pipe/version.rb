# frozen-string-literal: true

module CrackPipe
  MAJOR = 0
  MINOR = 2
  TINY  = 3
  VERSION = [MAJOR, MINOR, TINY].join('.').freeze

  def self.version
    VERSION
  end
end
