require_relative '../lib/active_record_binder'

# Helper
class Class
  def __DIR__
    File.expand_path File.dirname(__FILE__)
  end
end

class MockBond < Binder::AR
  database __DIR__ + '/foo.sqlite3'
  adapter  :sqlite3

  has_one :article
end

class OtherMockBond < Binder::AR
  database :bar
  adapter  :sqlite3
end

# See test/foo.sqlite3
class Article < ActiveRecord::Base
end
