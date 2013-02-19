require 'minitest/spec'
require 'minitest/autorun'

require 'mocha/setup'

require 'turn/autorun'
Turn.config.format = :pretty

class Class
  def __DIR__
    File.expand_path File.dirname(__FILE__)
  end
end

class MiniTest::Spec
  class << self
    alias :its :it
    alias :they :it
    alias :context :describe
  end
end
