require_relative './mocks'
require_relative '../lib/active_record_binder'

class FooCreateTable < MockBond::Version 1.0
  def self.up
    create_table :tags do |t|
      t.string :name
      t.integer :tag_id, default: 0
      t.timestamps
    end
  end

  def self.down
    drop_table :tags
  end
end

class BarCreateTable < MockBond::Version 1.1
  def self.up
    create_table :foobz do |t|
      t.string :foobar
      t.timestamps
    end
  end

  def self.down
    drop_table :foobz
  end
end
