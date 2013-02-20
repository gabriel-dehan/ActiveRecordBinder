require_relative './version'

module Binder
  class Help < Binder::Strategy
    def execute args
      instructions = []
      help_topics = merge_options_aliases

      help_topics.each do |topic|
        binder   = Module.nesting.last

        cmd_name = topic.split(" ").last.gsub(/^-*/, '').capitalize
        command =  binder.const_get(cmd_name)
        cmd_description = command.new.description

        instructions << format_instruction(topic.to_s, cmd_description)
      end

      Version.new.execute(nil) + "\n" +
      instructions.join("\n")
    end


    def format_instruction name, description
      "  #{name.ljust(justify_size).colorize(:green)} - #{description}"
    end

    def description
      "Displays the help"
    end

    alias_class :H
  end
end
