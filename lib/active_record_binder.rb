require 'active_record'
require 'active_support/core_ext/string'

# Private: A simple module that delegates classes methods when needed, keeping the calls in memory.
module DifferedDelegator
  def register_delegators *args
    args.each do |delegator|
      delegator = delegator.to_s
      module_eval %Q{
        def self.#{delegator} *parameters
          @delegators ||= []
          @delegators << { name: :#{delegator}, params: parameters }
        end
      }
    end
  end

  def delegate_to klass_or_object
    @delegators.each do |data|
      unless data.empty?
        name = data[:name]
        args = data[:params]
        klass_or_object.send(name, *args)
      end
    end
  end
end

class MigrationVersionError < Exception; end
class MigrationProcessError < Exception; end

# Public: Namespace containing classes to create binder to.
# A binder is simply a tool to use for Databases plugs or adaptors building.
module Binder
  # Public: Active Record Binder class. You need to inherit from it to create your Plug or Adaptor.
  #
  # Examples
  #
  #   class ARSqlitePlug < Binder::AR
  #     database 'db.sqlite3'
  #     adapter :sqlite3
  #
  #     # Your methods
  #   end
  #   #
  #   # Or
  #   class ARMySqlPlug < Binder::AR
  #     database 'db'
  #     adapter :mysql
  #     connect_with user: 'Foo', password: 'Bar', host: 'localhost'
  #
  #     # Your methods
  #   end
  #
  #   # You need to initialize the plug by passing it a table to handle
  #   plug = ARSqlitePlug.new :table_for_foo
  #   foo = plug.table # => the TableForFoo class, which inherit from ActiveRecord::Base.
  #   # Foo is an active record object linked to a table, you can use it as you would usually.
  #   foo.first
  #
  #   # Furthermore, the Binder::AR class, has some interesting class methods :
  #   #
  #   Binder::AR::default_database # => ENV['APP_DB'] # This value would be used if no database had been set during the plus creation.
  #   Binder::AR::database # => Returns the current database used by the Binder in general (Would default to ENV['APP_DB'] if not specified)
  #   ARSqlitePlug::database # => :db (Works the same and returns this Plug Class's database parameters)
  #   #
  #   # The same goes for the adapters :
  #   Binder::AR::default_adapter # => :sqlite3
  #   ARMySqlPlug::adapter # => :mysql
  #   #
  #   # And connection parameters
  #   Binder::AR::connection # => {}
  #   ARMySqlPlug::connection # => { :user => 'Foo', :password => 'Bar', :host => 'localhost' }
  #
  class AR
    extend DifferedDelegator

    attr_reader :table_name, :table
    register_delegators :has_many, :has_one, :has_and_belongs_to_many, :belongs_to

    # Public: Returns a new instance of the binder's class.
    # It also automaticaly establish a connection with the database throught the specified adapter,
    # but prevents trying to reconnect if the connection is already established.
    #
    # table_name - A String or Symbol representing the table to which we want to be bound.
    #
    # Examples
    #
    #   class Plug < Binder::AR; end
    #   plug = Plug.new :articles
    #   plug.table.find # [<Article#1>, <Article#2>] # Works, the connection has been established.
    #
    # Returns an instance of the binder's class.
    def initialize table_name
      @table_name = table_name

      # Retrieves or Create the ActiveRecord::Base subclass that will match the table.
      table = meta_def_ar_class

      # Handle ActiveRecord::Base delegation, to ensure painless associations
      self.class.delegate_to table

      # Establishes a connection to the database
      table.connect unless table.connected?
    end

    private
    # Private : creates an ActiveRecord::Base subclass matching the table name.
    #
    # _database - the database parameters
    # _adapter  - the adapter parameters
    # _params   - the connection parameters
    #
    # Returns the class object.
    def meta_def_ar_class
      klass  = table_name.to_s.classify
      binder = self.class

      @table =
        if binder.const_defined? klass
          binder.const_get klass
        else
          binder.const_set(klass,
          Class.new(ActiveRecord::Base) do                      # class `TableName` < ActiveRecord::Base
            singleton_class.send(:define_method, :connect) do   #   def self.connect
              ActiveRecord::Base.establish_connection(binder.connection_data)
            end                                                 #   end
          end)                                                  # end
        end #if
    end

    class << self
      # Public: Set the current database
      #
      # db - the database, as a String or Symbol. (default: Binder::AR.default_database)
      #
      # Examples
      #
      #   class Plug < Binder::AR
      #     database :foobar
      #   end
      #
      # Returns the current database.
      def database db = default_database
        if db == default_database
          @database ||= db
        else
          @database = db
        end
      end

      # Public: Set the current adapter
      #
      # adpt - the adapter, as a String or Symbol. (default: Binder::AR.default_adapter)
      #
      # Examples
      #
      #   class Plug < Binder::AR
      #     adapter :foobar
      #   end
      #
      # Returns the current database.
      def adapter adpt = default_adapter
        if adpt == default_adapter
          @adapter ||= adpt
        else
          @adapter = adpt
        end
      end
      alias :adaptor :adapter

      # Public: Set the current connection parameters
      #
      # opts - A Hash, containing options to pass to the ActiveRecord::Base.establish_connection call (default: {})
      #        user     - A user name as a String.
      #        password - A password as a String.
      #        host     - A host String.
      #
      # Examples
      #
      #   class Plug < Binder::AR
      #     adapter :foobar
      #   end
      #
      # Returns the current database.
      def connection opts = {}
        @connection ||= opts
      end
      alias :connect_with :connection

      # Public: Retrieves a clean set of connection data to establish a connection
      #
      # Returns a Hash.
      def connection_data
        opts = { database: self.database, adapter: self.adapter }.merge(self.connection)
      # We ensure we have a string for the adapter
        opts[:adapter] = opts[:adapter].to_s
        # If we have a symbol for the database and the adapter is sqlite3, we create a string and add '.sqlite3' to the end
        opts[:database] = "#{opts[:database]}.sqlite3" if opts[:adapter] == 'sqlite3' and opts[:database].class == Symbol
        opts
      end

      # Public: Retrieves de default database
      #
      # Returns a the content of ENV\['APP_DB'\].
      def default_database; ENV['APP_DB'] end

      # Public: Retrieves de default database
      #
      # Returns a the content of :sqlite3, as a Symbol.
      def default_adapter;  :sqlite3 end

      # Public: Creates a new migration version through subclassing.
      #
      # n - A migration version number as Float.
      #
      # Examples
      #
      #   class Plug < Binder::AR; end
      #
      #   class CreateFooTable < Plug::Version 1.0
      #     def self.up
      #       create_table :foos do |t|
      #         t.string :name
      #         t.timestamps
      #       end
      #     end
      #
      #     def self.down
      #       drop_table :foos
      #     end
      #   end
      #
      #   class CreateBarTable < Plug::Version 1.1
      #     def self.up
      #       create_table :bars do |t|
      #         t.string :title
      #         t.timestamps
      #       end
      #     end
      #
      #     def self.down
      #       drop_table :bars
      #     end
      #   end
      #
      #   # You can get the migration version for a pecular migration class.
      #   CreateFooTable.version # => 1.0
      #   CreateBarTable.version # => 1.1
      #
      # Returns a new Class, subclassing ActiveRecord::Migration.
      def Version n
        @last_version = [n, @last_version.to_f].max # Assign or retrieves the last migration version number
        # migrations is a pointer to the instance variable
        migrations = (@migrations ||= [])
        Class.new(ActiveRecord::Migration) do
          singleton_class.send(:define_method, :version) do   #  def self.version
            n                                                 #    n
          end                                                 #  end

          # Callback invoked whenever a subclass of the current class is created
          singleton_class.send(:define_method, :inherited) do |s|  # def self.inherited subclass
            migrations << s                                        #     migrations << subclass
          end                                                      # end
        end
      end

      # Public: Executes a migration.
      #
      # version - A Float or Numeric indicating the number towards which execute the migration.
      #           If none specified it will migrate to the latest migration.
      #
      # Examples
      #
      #   # (See the Binder::AR::Version examples for the classes definition.)
      #   Plug.migrate 1.0 # Creates table bars.
      #   # => 1.0
      #   Plug.migrate 0   # Drop the table bars.
      #   # => 0.0
      #   Plug.migrate     # Creates tables bars and foos.
      #   # => 1.1
      #
      # Returns the version we migrated to as a Float.
      def migrate version = nil
        if @migrations
          schema  = meta_schema
          version = __check_migration_version(version)
          __create_meta_data_table_for(schema)

          s = schema.first || schema.new(version: 0)
          unless s.version == version
            @migrations.sort_by { |migration| migration.version }.each do |m|
              m.migrate(:up) if s.version < m.version and m.version <= version

              if s.version >= m.version and m.version > version
                m.migrate(:down)
              else # Handle migrate(0)
                m.migrate(:down) if s.version >= m.version and version.zero?
              end
            end
            s.update_attribute :version, version
          end
          version = s.version
        end
        version
      end

      # Private: Get the Class holding the current migration metadatas.
      #
      # Returns an ActiveRecord::Base subclass.
      def meta_schema
        klass = :MetaSchema
        @meta_schema ||=
          if self.const_defined?(klass)
            self.const_get(klass)
          else
            self.__create_meta_schema_class(klass)
          end
      end

      # private class methods

      # Private : Create a table for the current meta schema.
      #
      # schema - The schema Class for which we want to create the table.
      #
      # Examples
      #
      #   __create_meta_data_table_for MyPlug # Will create a my_plug_meta_schemas table.
      #
      # Returns Nothing.
      def __create_meta_data_table_for schema
        ActiveRecord::Base.establish_connection(self.connection_data) unless schema.connected?

        # Clears the table cache for the schema (remove TableDoesNotExists if a table actually exists)
        schema.clear_cache!

        unless schema.table_exists?
          ActiveRecord::Schema.define do
            create_table schema.table_name do |t|
              t.column :version, :float
            end
          end
        end
      end

      # Private : checks the migration version number
      #
      # Raises MigrationVersionError if the required version does not exist.
      #
      # Returns the version as a Float.
      def __check_migration_version version
        raise MigrationVersionError if not version.nil? and @last_version < version
        version ||= @last_version
      end

      # Private: Creates the meta schema class, and binds it to the current Namespace.
      #
      # Examples
      #
      #   class Plug < Binder::AR; end
      #   __create_meta_schema_class "MetaSchema"
      #   # => Plug::MetaSchema
      #
      # Returns a new Class inheriting from ActiveRecord::Base.
      def __create_meta_schema_class klass
        binder = self.name
        self.const_set(klass,
          Class.new(ActiveRecord::Base) do                                # class MetaSchema < ActiveRecord::Base
            singleton_class.send(:define_method, :table_name_prefix) do   #   def self.table_name_prefix
              "#{binder.underscore}_"                                   #     "foo_binder" # If we have a class FooBinder < Binder::AR
            end                                                           #   end
          end)                                                            # end
      end

    end
  end
end
