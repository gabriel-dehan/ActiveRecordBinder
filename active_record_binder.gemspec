# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'version'

Gem::Specification.new do |s|
  s.name         = 'active-record-binder'
  s.version      = Binder::VERSION
  s.date         = '2013-02-20'
  s.summary      = 'Ruby library to ease the process of interfacing with ActiveRecord. Allows to create simple and elegant migrations.'
  s.description  = 'A Ruby library to ease the process of interfacing with ActiveRecord. Allows to create simple and elegant migrations.'
  s.authors      = ['GabrielDehan']
  s.email        = 'dehan.gabriel@gmail.com'
  s.homepage     = 'https://github.com/gabriel-dehan/ActiveRecordBinder'

  s.add_dependency('activerecord')

  s.files = %w(README.md) + Dir.glob("{bin,doc,test,lib,extras}/**/**/*")

  s.executables  = ['arb']
  s.require_path = "lib"
  s.bindir = "bin"
end