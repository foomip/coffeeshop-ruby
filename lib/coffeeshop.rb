require 'concurrent'

require 'assets/coffee_bar'
require 'assets/coffee_machine'
require 'assets/table'
require 'dataset'
require 'people/barista'
require 'people/maitre_d'
require 'people/waiter'
require 'utils/message_printer'

class Coffeeshop
  attr_reader :arrival_variance, :maitre_d, :table_customers, :coffee_bar_customers

  def self.open_for_business
    dataset = Dataset.get

    arrival_variance      = dataset.customers.arrival_variance
    table_customers       = dataset.customers.table_customers
    coffee_bar_customers  = dataset.customers.coffee_bar_customers

    coffee_machines   = Assets::CoffeeMachine.buy_coffee_machines
    baristas          = People::Barista.hire_baristas coffee_machines
    coffee_bar        = Assets::CoffeeBar.build_coffee_bar coffee_machines, baristas
    tables            = Assets::Table.build_tables
    waiters           = People::Waiter.hire_waiters tables, coffee_bar
    maitre_d          = People::MaitreD.hire_maitre_d tables, coffee_bar
    coffeeshop        = Coffeeshop.new arrival_variance, maitre_d, table_customers,
                          coffee_bar_customers

    baristas.each { |b| b.tell [:coffee_bar_ready, coffee_bar] }

    coffeeshop.run
    coffeeshop
  end

  def initialize *args
    @arrival_variance, @maitre_d, @table_customers, @coffee_bar_customers = args
  end

  def run
    # merge 2 lists and then randomly sample from them
    customers_list = table_customers.map { |c| [:table, c] } +
    coffee_bar_customers.map { |c| [:coffee_bar, c] }

    handle_customer_arrival customers_list
  end

  def handle_customer_arrival customers_list
    if customers_list.length > 0
      Concurrent::ScheduledTask.new(arrival_variance.sample) do
        customer = customers_list.sample

        maitre_d.tell [:customer_arrived, [customer, Time.now]]
        customers_list.delete customer

        handle_customer_arrival customers_list
      end.execute.wait # << BAD
    else
      wait_for_empty_coffee_shop
    end
  end

  def wait_for_empty_coffee_shop
    Concurrent::ScheduledTask.new(2) do
      wait_for_empty_coffee_shop unless maitre_d.ask! [:coffeeshop_empty]
    end.execute.wait # << BAD
  end
end
