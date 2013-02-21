# Private: A simple module that delegates classes methods when needed, keeping the calls in memory.
#
# Examples
#
#   class Foo
#     def self.foo arg
#       "World of #{arg}"
#     end
#     #
#     def self.bar
#       "Hello"
#     end
#   end
#
#   class Baz
#     extend DeferedDelegator
#     register_delegators :bar, :foo
#     #
#     def initialize obj
#       @obj = obj
#     end
#     #
#     def foobar
#       delegate_to @obj
#     end
#   end
#
#   class Bar < Baz
#     foo "Foo"
#     bar
#   end
#
#   Bar.new Foo
#   Bar.foobar
#   # => "World of Foo"
#   # => "Hello"
module DeferedDelegator
  # Public: Allows to register delegators
  #
  # args - List of Symbols, the method name that will be delegated.
  #
  # Returns Nothing.
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

  # Public: Triggers the delegation and run the delegated methods
  #
  # klass_or_object - A Class or an Object to delegate to.
  #
  # Returns Nothing.
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
