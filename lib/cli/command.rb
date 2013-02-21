require_relative './command_parser'
require_relative './core_ext'

module Binder
  # Public: A Class to create Command Line Tool commands.
  #
  # Examples
  #
  #   Binder::Command.new ARGV
  #   # => Will execute any command passed in ARGV
  #   # A command is just a ruby Class, subclassing the Binder::Strategy Class.
  #   #
  #   # When you do :
  #   Binder::Command.new "migrate --version 1.1"
  #   # => The Binder::Migrate class is instanciated and it's execute method is called.
  class Command
    def initialize args
      raise CommandParser::ParseError.new("No command specified.") if args.empty?

      # ['--migrate' 'param'] => 'migrate'
      command  = args.shift.gsub(/\-/, '')

      strategy = Binder::const_get(command.capitalize).new
      puts strategy.execute args
    end
  end

  # Public: A Strategy is a way to declare a specific command.
  # You need to subclass the Binder::Strategy class and declare an `execute` method and a `description` method.
  #
  # Examples
  #
  #   class Migrate < Binder::Strategy
  #     def execute args
  #       # Parse args and do migration stuff
  #       "Migration Done." # <= Binder::Command.new automaticaly renders the return value of an `execute` call
  #     end
  #     #
  #     # The description call is mainly used by the `help` command.
  #     def description
  #       "Easier Migration. Use the " + "--directory".colorize(:orange) + " option to pass in a directory to load."
  #       # Yeah, notice the "colorize" String method that helps you write a string in a beatiful color.
  #     end
  #   end
  class Strategy
    # Public: creates an alias for the command.
    #
    # Examples
    #
    #   class Migrate < Binder::Strategy
    #     # def execute...
    #     # def description...
    #     #
    #     alias_class :M
    #     # => This will create an alias :M class and this the existance of the corresponding "-m" command. (`arb --migrate` or `arb -m`, now)
    #   end
    def self.alias_class _alias
      Binder::const_set(_alias, Class.new(self))
    end

    # Public: returns the String size of the biggest command or option group.
    #
    # Returns a Numeric.
    def justify_size
      if @options.nil?
        Binder::Strategy.subclasses.map(&:to_s).group_by(&:size).max.flatten.first - "Binder".length
      else
        @options.group_by(&:size).max.flatten.first
      end
    end

    # Public: merge options and aliases "-m, --migrate, -h, --help", etc...
    #
    # Uses an array of commands : ["-h" "-m", "--help", "--migrate"],
    #
    # and concatenate the aliases : ["-m, --migrate", "-h, --help"]
    #
    # Returns an Array of merged aliases.
    def merge_options_aliases
      commands     = Binder::Strategy.subclasses.map { |command| command.to_s.gsub!('Binder::', '').downcase }.sort
      previous_cmd = ""
      options      = []

      commands.each_with_index do |cmd, i|
        if cmd.length == 1
          previous_cmd = cmd
        elsif not previous_cmd.empty?
          cmd_prefixes = [previous_cmd.length == 1 ? '-' : '--', cmd.length == 1 ? '-' : '--']
          options << "#{cmd_prefixes.first}#{previous_cmd}, #{cmd_prefixes.last}#{cmd}"
          previous_cmd = ""
        end
      end
      @options = options
    end

    # Public: provides a default description if not defined.
    #
    # Returns a "No description found" String.
    def description; "No description found" end
  end
end
