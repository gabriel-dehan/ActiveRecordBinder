require '../lib/version'

Gem::Specification.new do |s|
  s.name         = 'active-record-binder'
  s.version      = Binder::VERSION
  s.date         = '2013-02-20'
  s.summary      = 'Ruby library to ease the process of interfacing with ActiveRecord. Allows to create simple and elegant migrations.'
  s.description  = 'Ruby library to ease the process of interfacing with ActiveRecord. Allows to create simple and elegant migrations.'
  s.authors      = ['GabrielDehan']
  s.email        = 'dehan.gabriel@gmail.com'
  s.files        = ['lib/active_record_binder.rb']
  s.homepage     = 'https://github.com/gabriel-dehan/ActiveRecordBinder'
end