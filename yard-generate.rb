# require 'yard'

if ARGV[0] == 'install'
  puts `gem install yard`
  puts `gem install yard-tomdoc`
elsif ARGV[0] == 'server'
  recursive_path = '**/**/**/**/**/**/**/**/*.rb'
  puts 'Generating doc...'
  puts system("yardoc '#{['lib/', 'app/'].map do |el| el + recursive_path end.join("' '")}' --protected --private --plugin yard-tomdoc")
  puts 'Yard server running on port :8808'
  `yard server`
end
