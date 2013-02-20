require_relative './command_parser'
require_relative './core_ext'

module Binder
  class Command
    def initialize args
      raise CommandParser::ParseError.new("No command specified.") if args.empty?

      # ['--migrate' 'param'] => 'migrate'
      command  = args.shift.gsub(/\-/, '')

      strategy = Binder::const_get(command.capitalize).new
      puts strategy.execute args
    end
  end

  class Strategy
    def self.alias_class _alias
      Binder::const_set(_alias, Class.new(self))
    end

    def justify_size
      if @options.nil?
        Binder::Strategy.subclasses.map(&:to_s).group_by(&:size).max.flatten.first - "Binder".length
      else
        @options.group_by(&:size).max.flatten.first
      end
    end

    # Merge options and aliases -m, --migrate, -h, --help, etc...
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

    def description; "No description found" end
  end
end
