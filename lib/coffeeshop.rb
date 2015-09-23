require 'assets/table'
require 'assets/coffee_machine'
require 'assets/coffee_bar'
require 'people/waiter'

class Coffeeshop
  attr_reader :tables, :waiters, :coffee_machine

  def self.open_for_business
    tables            = Assets::Table.build_tables
    waiters           = People::Waiter.hire_waiters tables
    coffee_machine    = Assets::CoffeeMachine.spawn(:coffee_machine_1)
    coffee_bar        = Assets::CoffeeBar.build_coffee_bar coffee_machine
    coffeeshop        = Coffeeshop.new tables, waiters, coffee_machine, coffee_bar
    # coffeeshop.run
    coffeeshop
  end

  def initialize *args
    @tables, @waiters, @coffee_machine, @coffee_bar = args

    p self
  end
end
