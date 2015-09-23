require 'concurrent-edge'

require 'dataset'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    attr_reader :places, :coffee_machine, :baristas

    def self.build_coffee_bar coffee_machine, baristas
      places = Dataset.get.coffee_bar_places

      CoffeeBar.spawn :coffee_bar, places, coffee_machine, baristas
    end

    def initialize places, coffee_machine, baristas
      @places         = places
      @coffee_machine = coffee_machine
      @baristas       = baristas
    end
  end
end
