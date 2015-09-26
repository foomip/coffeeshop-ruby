require 'dataset'
require 'assets/table'
require 'assets/coffee_machine'
require 'assets/coffee_bar'
require 'people/maitre_d'
require 'people/waiter'
require 'people/barista'

class Coffeeshop
  attr_reader :arrival_variance, :maitre_d

  def self.open_for_business
    coffee_machine    = Assets::CoffeeMachine.spawn(:coffee_machine_1)
    baristas          = People::Barista.hire_baristas coffee_machine
    coffee_bar        = Assets::CoffeeBar.build_coffee_bar coffee_machine, baristas
    arrival_variance  = Dataset.get.arrival_variance
    tables            = Assets::Table.build_tables
    waiters           = People::Waiter.hire_waiters tables
    maitre_d          = People::MaitreD.hire_maitre_d tables, coffee_bar

    coffeeshop = Coffeeshop.new arrival_variance, maitre_d
    coffeeshop.run
    coffeeshop
  end

  def initialize *args
    @arrival_variance, @maitre_d = args
  end

  def run
    table_customers       = Dataset.get.table_customers
    coffee_bar_customers  = Dataset.get.coffee_bar_customers

    # merge 2 lists and then randomly sample from them
    customers_list = table_customers.map { |c| [:table, c] } +
    coffee_bar_customers.map { |c| [:coffee_bar, c] }

    while customers_list.length > 0
      customer = customers_list.sample

      maitre_d.tell [:customer_arrived, [customer, Time.now]]

      customers_list.delete customer
      sleep arrival_variance.sample
    end

    loop do
      break if maitre_d.ask! [:coffeeshop_empty]
      sleep 2
    end
  end
end
