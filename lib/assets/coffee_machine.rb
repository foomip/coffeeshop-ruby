require 'concurrent-edge'

require 'dataset'

module Assets
  class CoffeeMachine < Concurrent::Actor::RestartingContext
    def self.buy_coffee_machines
      Dataset.get.total.coffee_machines.times.map do |i|
        CoffeeMachine.spawn "Coffee machine #{i}"
      end
    end
  end
end
