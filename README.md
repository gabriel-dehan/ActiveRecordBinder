[ActiveRecordBinder](https://rubygems.org/gems/active-record-binder)
============
```
arb -v
# => 1.2.0

arb --changelog
# V 1.2.0 : Bug fixes, refactoring and introduction of the new command-line-tool : `arb`
# V 1.1.0 : Introducing delegation for ActiveRecord::Base relation methods.
# V 1.0.1 : Minor fixes and Documentation creation.
# V 1.0.0 : Release
#
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

# Relations
If it pleases you, you can create your relations directly in the Binder class. Those methods call are delegated to the underlying table model when initiated.

```ruby
  class FooBinder < Binder::AR
    has_one :bar
  end
  class BarBinder < Binder::AR
    belongs_to :foo
  end

  # And (if the table are accordingly populated, see "The Migration System", below) :
  foo = FooBinder.new(:foo).table
  foo.first.bar # => <BarObject>
```

Delegated methods are the following : `has_many`, `has_one`, `has_and_belongs_to_many`, `belongs_to`.

# The Migration System

I've always found the ActiveRecord::Migration system a bit of a pain to use.

Therefore, I took the liberty of using pieces of [`_Why's Camping Web Framework's`](https://github.com/camping/camping/) migration system.
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

# The Command Line Tool
Active Record Binder ships with a neat little CLI : `arb`

ARB is a small easily extandable Command Line Interface. And it's pretty. Beautiful colors everywhere. Awesome. Seriously.
To use it :
```
$ arb version
# => Binder::AR::Version => 1.2.0
```

You can display the help using `arb help` or `arb -h`

But, the most intersting part of this CLI is the migrate command. You can easily run your migrations for a specific plug :
```
$ arb migrate --version 1.1 --directory migrations/ --adapter MySqlitePlug
```
Will migrate to 1.1, using the migrations found in the `migrations/` directory and calling `MySqlitePlug.migrate`.

You can specify multiples options, and there is an alternative syntax :
```
# => You can specify multiple directories through `--directory` or `--d`
$ arb migrate -v 0 -d migrations/foo/ migrations/bar -a MySqlitePlug

# => You can load directories recursively with `-r` or `--recursive`
$ arb migrate -v 0 --recursive migrations/ --plug MySqlitePlug

# => You can can also load files using `-f` or `--file`
$ arb migrate -v 1.0 -f migrations/foo/create_foo_table.rb --adapter MySqlitePlug
```

<img src="https://raw.github.com/gabriel-dehan/ActiveRecordBinder/master/extras/cli_help.png" alt="Command Line Interface screenshot"/>

# Want to know more ?
[Checkout the documentation !](http://rubydoc.info/gems/active-record-binder/1.0.1/frames)
Or dive in, the code is pretty straightforward and well documented. And there is a lot of tests.

# Want to contribute ?
Please, do fork and pull request !

## Road map:
* Maybe create other Binder, like MongoDB, Datamapper, like `Binder::Mongo`, `Binder::DataMapper`. But the gem's name would have to change.
