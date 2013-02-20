module CommandParser
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
