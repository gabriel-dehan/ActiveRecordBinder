module CommandParser
  # Public: Parse options and creates an array of hash data for each.
  #
  # args - An Array of options and parameters to parse.
  #
  # Examples
  #
  #   CommandParser::parse_options "--directory lib/ migrations/ --adapter MySqlPlug"
  #   # => [{ option: 'directory', option_args: ["lib/", "migrations/"] }, { option: 'adapter', option_args: ["MySqlPlug"] }]
  #
  # Returns a parsed array.
  def self.parse_options(args)
    parsed = []
    last_option = ""
    args.each do |chunk|
      if chunk[/^-*/].empty?
        raise CommandParser::ParseError.new("Arguments given but no option has been specified.") if last_option.empty?
        cur_cmd = parsed.last
        cur_cmd[:options_args] ||= []
        cur_cmd[:options_args] << chunk
      else
        parsed << { option: chunk.sub(/^-*/, '') } and last_option = chunk
      end
    end
    parsed
  end

  class CommandParser::ParseError < StandardError; end
end
