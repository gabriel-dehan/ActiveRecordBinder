require 'version'

module Binder
  class Version < Binder::Strategy
    def execute args
      "Binder::AR::Version => #{Binder::VERSION}".colorize(:orange)
    end

    def description
      "Displays Binder::AR's gem current version"
    end

    alias_class :V
  end
end
