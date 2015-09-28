require 'assets/coffee_bar'
require 'assets/coffee_machine'
require 'dataset'
require 'people/barista'
require 'utils/message_printer'

class Coffeeshop
  def self.open_for_business
    dataset = Dataset.get

    arrival_variance  = dataset.customers.arrival_variance

    coffee_machines   = Assets::CoffeeMachine.buy_coffee_machines

    baristas          = People::Barista.hire_baristas coffee_machines

    coffee_bar        = Assets::CoffeeBar.build_coffee_bar coffee_machines, baristas
    baristas.each { |b| b.tell [:coffee_bar_ready, coffee_bar] }

    sleep 5
  end
end
