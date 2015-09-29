require 'concurrent-edge'

require 'dataset'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    def self.build_coffee_bar coffee_machines, baristas
      places = Dataset.get.total.coffee_bar_places

      CoffeeBar.spawn :coffee_bar
    end
  end
end
