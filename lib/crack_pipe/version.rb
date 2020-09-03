# frozen-string-literal: true

module CrackPipe
  MAJOR = 0
  MINOR = 3
  TINY  = 0
  VERSION = [MAJOR, MINOR, TINY].join('.').freeze

  def self.version
    VERSION
  end
end
