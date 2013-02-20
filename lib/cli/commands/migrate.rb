require 'active_record_binder'

module Binder
  class Migrate < Binder::Strategy
    def execute args
      commands = CommandParser::parse_options(args)
      commands.each do |c|
        option = c[:option]
        args   = c[:options_args]
        self.send(option.to_sym, args)
      end
      "\nDone."
    end

    def version version
      puts "Migrating toward version #{version.first.to_f.to_s.colorize(:orange)}"
      @version ||= version.first.to_f
    end
    alias :v :version
    alias :to :version

    def plug args
      args.each do |klass|
        raise MigrationProcessError.new("Plug #{klass.colorize(:red)} not found.") unless Object.const_defined?(klass)
        Object.const_get(klass).migrate @version
      end
    end
    alias :a :plug
    alias :adapter :plug
    alias :adaptor :plug

    def directory blobs, recursively = false
      blobs.each do |blob|
        original_name  = blob
        blob = File::absolute_path(blob)
        raise CommandParser::ParseError.new("Invalid argument : no such file or directory #{blob}.") unless File::exists?(blob)

        if File::directory?(blob)
          files = Dir.glob("#{blob}/*")
          files.each do |file|
            if recursively == true && File::directory?(file)
              directory [file], true
            end
            # Requires the file and logs it on stdout
            puts _require_path(file) unless File::directory?(file)
          end
        else
          puts _require_path(blob)
        end
      end
    end
    def _require_path path; "Requiring #{path.colorize(:green)}: #{require(path).to_s.colorize(:orange)}" end
    alias :d :directory
    alias :file :directory
    alias :f :directory

    def recursive blobs
      directory blobs, true
    end
    alias :r :recursive

    def description
      indent = ' ' * (justify_size * 2)

      str = []
      str << "Migrate to the specified version"
      str << "#{indent}" + "-v".colorize(:rose) + ", --version".colorize(:rose) + ", --to".colorize(:rose) + "    - Version we want to migrate to"
      str << "#{indent}" + "-d".colorize(:rose) + ", --directory".colorize(:rose) + "        - Allow to specify a set of directories holding your migrations"
      str << "#{indent}" + "-r".colorize(:rose) + ", --recursive".colorize(:rose) + "        - Same as `--directory` but will search recursively in the directories"
      str << "#{indent}" + "-f".colorize(:rose) + ", --file".colorize(:rose) + "             - Allow to specify a set of files holding your migrations"
      str << "#{indent}" + "-a".colorize(:rose) + ", --adapter".colorize(:rose) + ", --plug".colorize(:rose) + "  - Specify a Binder class on which to run the migration"
      str.join("\n")
    end

    alias_class :M
  end
end
