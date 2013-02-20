require_relative 'minitest_helper'
require_relative '../lib/active_record_binder'
require_relative './mocks'
require_relative './migrations'

describe Binder::AR do
  describe 'Database information' do
    context 'default' do
      it 'should have a sensible default to an ENV variable' do
        ENV['APP_DB'] = 'Foo'
        Binder::AR.default_database.must_equal ENV['APP_DB']
      end
    end # default

    context 'specified' do
      it 'should have a way to set a database' do
        Binder::AR.database 'Foobar'
        Binder::AR.database.must_equal 'Foobar'
      end
      it 'should switch to default if nothing is specified' do
        Binder::AR.database nil
        Binder::AR.database.must_equal Binder::AR.default_database
      end
      context 'each subclass' do
        it 'should have different settings from another' do
          MockBond.database 'Bar'
          OtherMockBond.database 'Baz'
          MockBond.database.must_equal 'Bar'
          OtherMockBond.database.must_equal 'Baz'
        end
      end
    end # Specified
  end # Database

  describe 'Connection adapter' do
    context 'default' do
      it 'should use sqlite as a default adapter' do
        Binder::AR.default_adapter.must_equal :sqlite3
      end
    end
    context 'specified' do
      it 'should give a way to set a specific adapter' do
        Binder::AR.adapter :mysql2
        Binder::AR.adapter.must_equal :mysql2
      end
      it 'should use sqlite if nothing is specified' do
        Binder::AR.adapter nil
        Binder::AR.adapter.must_equal Binder::AR.default_adapter
      end
      context 'each subclass' do
        it 'should have different settings from another' do
          MockBond.adapter 'Bar'
          OtherMockBond.adapter 'Baz'
          MockBond.adapter.must_equal 'Bar'
          OtherMockBond.adapter.must_equal 'Baz'
        end
      end
    end # specified
  end # Connection adapter

  describe 'Connection params' do
    it 'should give a way to set connection parameters' do
      params =  { user: 'Poney', password: 'Poney234' }
      Binder::AR.connect_with params
      Binder::AR.connect_with.must_equal params
    end
  end

  describe 'Binder Object' do
    let(:binder) { MockBond.new :foo }
    it 'On instanciation, should automaticaly create an AR Record object matching the table name and namespaced under the current binder class' do
      binder.table.must_equal binder.class::Foo
    end
  end # Connection parms

  describe 'AR Bound Object' do
    let(:model) { MockBond.new(:foo).table }

    it 'should be an instance of a subclass ActiveRecord::Base' do
      model.superclass.must_equal ActiveRecord::Base
    end

    describe 'connection' do
      it 'should respond to connect' do
        model.must_respond_to :connect
      end
      it 'should respond to connected?' do
        model.must_respond_to :connected?
      end
      it 'should be connected automaticaly on instanciation' do
        # Should be replace with something else, but it activates the connection so it's pretty easy
        model.first
        model.connected?.must_equal true
      end
    end

    describe 'ActiveRecord methods' do
      it 'should respond to find' do
        model.must_respond_to :find
      end
      it 'should respond to first' do
        model.must_respond_to :first
      end
      it 'should respond to all' do
        model.must_respond_to :all
      end
      it 'should respond to delete' do
        model.must_respond_to :delete
      end
      it 'should respond to update_attributes' do
        model.first.must_respond_to :update_attributes
      end
      it 'should respond to save' do
        model.new.must_respond_to :save
      end
    end

    describe 'ActiveRecord relations' do
      it 'should handle one to one relationships' do
        model.has_one :article
        model.first.article.must_equal Article.first
      end

      # As it's active record, it should work with other associations types too.
      # TODO: Test other associations
    end
  end # Ar Bound Object

  describe 'Migration system' do
    context 'schema definition' do
      let(:migration) { FooCreateTable }

      it 'should have a Version method' do
        Binder::AR.must_respond_to :Version
      end

      it 'inheriting through the Version method should create a subclass of ActiveRecord::Migration' do
        migration.superclass.superclass.must_equal ActiveRecord::Migration
      end

      context 'Versionning' do
        it "should have a version method, that returns this migration's version" do
          migration.version.must_equal 1.0
        end
      end
    end # schema definition

    context 'migration' do
      it 'should have a migrate method' do
        Binder::AR.must_respond_to :migrate
        MockBond.must_respond_to :migrate
      end

      it 'should create a schema containing the metadata for the migration system, namespaced inside the binder' do
        # Reset migrations
        MockBond.migrate 0
        MockBond.migrate
        MockBond::MetaSchema.must_be_kind_of Object
      end

      it 'can take a version number as an argument and return the executed-down-to migration number' do
        MockBond.migrate(1.0).must_equal 1.0
      end

      it 'should fail if the migration version specified does not exist' do
        ->{ MockBond.migrate(10.0) }.must_raise MigrationVersionError
      end

      describe 'migrate up and down' do
        before do
          # Make sure that we are at the first migration
          MockBond.migrate 0
          MockBond.migrate 1.0
          @schema = MockBond.meta_schema
         end

        it 'should set the current migration to the desired number' do
          MockBond.migrate 1.1
          @schema.first.version.must_equal 1.1
        end
        it 'should make the change for the desired migration' do
          MockBond.migrate 1.1
          tags = MockBond.new(:tag).table
          tags.create(name: 'foobar')
          tags.first.name.must_equal "foobar"
        end

        describe 'version unspecified' do
          it 'should migrate to the last version' do
            MockBond.migrate
            @schema.first.version.must_equal 1.1
          end
        end
      end

      context 'Schema MetaDatas' do
        before do
          MockBond.meta_schema
        end

        it 'should inherit from ActiveRecord::Base' do
          MockBond::MetaSchema.superclass.must_equal ActiveRecord::Base
        end

        describe 'Meta schema' do
          let(:meta_schema) { MockBond.meta_schema }

          it 'should be accessible through the method schema_meta' do
            meta_schema.must_equal MockBond::MetaSchema
          end

          it 'should create a metadata table namespaced under the binder class name' do
            meta_schema.table_name.must_equal "mock_bond_meta_schemas"
          end

          its 'table should have a version column' do
            meta_schema.new.must_respond_to :version
          end
        end # Describe Meta Schema
      end # Context Schema Metadatas

    end
  end
end

class TestDelegators
  extend DifferedDelegator
end

class TestDelegatedTo
  def self.foo
    @@test ||= []
    @@test << true
  end

  def self.bar
    @@test ||= []
    @@test << false
  end

  def self.test
    @@test
  end
end

describe DifferedDelegator do
  it 'provides a way to register delegators for a class' do
    TestDelegators.register_delegators :foo
    TestDelegators.must_respond_to :foo
  end

  it 'provides a way to call the delegation process and execute every registered delegation' do
    TestDelegators.register_delegators :foo, :bar

    TestDelegators.foo
    TestDelegators.bar

    TestDelegators.delegate_to TestDelegatedTo

    TestDelegatedTo.test.must_equal [true, false]
  end
end
