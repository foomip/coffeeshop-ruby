require 'concurrent-edge'

require 'dataset'

module Assets
  class CoffeeBar < Concurrent::Actor::RestartingContext
    attr_reader :places, :coffee_machine, :baristas

    def self.build_coffee_bar coffee_machine
      places = Dataset.get.coffee_bar_places

      CoffeeBar.spawn :coffee_bar, places, coffee_machine
    end

    def initialize places, coffee_machine
      @places         = places
      @coffee_machine = coffee_machine
      @baristas       = []
    end
  end
end
