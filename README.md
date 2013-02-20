[ActiveRecordBinder](https://rubygems.org/gems/active-record-binder)
============
```
arb -v
# => 1.0.1
```
A Ruby library for an easier interfacing with ActiveRecord. And an easier way to create elegant migrations.

# Installation
`gem install active-record-binder`

# Why Binder ? What the frak is this ?
I needed a tool to ease the creation of little Plugs and Adapters for ActiveRecord.

The idea is that you Bind a class to ActiveRecord by subclassing it with Binder::AR.
You can specify your own methods and delegate to ActiveRecord whenever you need.

It's kind of a Proxy on steroids, that will do a lot for you.

## Show me !
You want to create a Plug for your sqlite database :

```ruby
  class SqlitePlug < Binder::AR
  end
```

Those lines will create a new `MySqlPlug`, and it will connect to the database specified by your `ENV['APP_DB']`.
Also, the database adapter defaults to `:sqlite3`.

Now. All this is fine. But you want more :
* You want to select a precise database without using `ENV['APP_DB']`;
* Your application uses MySQL.

```ruby
  class MySqlPlug < Binder::AR
    database :db
    adapter :mysql
    connect_with user: 'Foo', password: 'Bar', host: 'localhost'
  end
```

As you can see : you can specify a database or an adapter by passing a `Symbol` or a `String` to both the
* `database()` and the
* `adapter()` methods.

The `connect_with()` method can be used to pass a `Hash` of options to the `ActiveRecord::Base.establish_connexion()` call.

_Please notice that all your instances of MySqlPlug will use those values once defined this way._

## How do we use this ?

```ruby
  class MySqlPlug < Binder::AR
    database :db
    adapter :mysql
    connect_with user: 'Foo', password: 'Bar', host: 'localhost'

    def find args
      # But you could use a delegator
      table.find args
    end
  end

  # A Model
  class Foo
    def initialize
      # Will bind this instance of the MySqlPlug to the `foos` table
      @plug = MySqlPlug.new :foo
    end

    def find
      # But you could use a delegator
      @plug.find
    end
  end
```

**Note :** You can use the `table` method on any instance of your Plug to get the table class (An ActiveRecord Class Object).

```ruby
  @plug = MySqlPlug.new :foo
  table = @plug.table
  # => MySqlPlug::Foo
  table.find # ActiveRecord method call.
  # => [<FooObject#1>, <FooObject#2, ...]
```

Notice how neatly namespaced is the ActiveRecord table class. This way we won't step over our `Foo` model.

# The Migration System

I've always found the ActiveRecord::Migration system a bit of a pain to use.

Therefore, I took the liberty of using part of (`_Why's Camping Web Framework`)[https://github.com/camping/camping/] migration system.
You can now create your migrations this way :

```ruby
   class CreateFooTable < MySqlPlug::Version 1.0
     def self.up
       create_table :foos do |t|
         t.string :name
         t.timestamps
       end
     end

     def self.down
       drop_table :foos
     end
   end

   class CreateBarTable < MySqlPlug::Version 1.1
     def self.up
       create_table :bars do |t|
         t.string :title
         t.timestamps
       end
     end

     def self.down
       drop_table :bars
     end
   end

  # You can get the migration version for a pecular migration class.
  CreateFooTable.version # => 1.0
  CreateBarTable.version # => 1.1
```

Isn't it neat ?.

Now, boy : just use the `migrate` method to execute your migrations.

```ruby
  MySqlPlug.migrate
  # => 1.1
```
This executes everything up to the latest migration.
But `migrate()` can also take a version number as an argument.

```ruby
  MySqlPlug.migrate 0
  # => 0.0
```
This, will migrate everything down, reverting the changes as specified in each reverted migration `self.down` method.
```ruby
  MySqlPlug.migrate 1.0
  # => 1.0
```
And finally, this will migrate up until it hits 1.0.

# Want to know more ?
(Checkout the documentation !)[]

# Want to contribute ?
Please, do fork and pull request !

## Road map:
* Create a command line tool : `arb`
* Add a `arb migrate` command that will be able to execute migration and be linked to any developer's ruby script.
* Maybe create other Binder, like MongoDB, Datamapper, like `Binder::Mongo`, `Binder::DataMapper`. But the gem's name would have to change.
