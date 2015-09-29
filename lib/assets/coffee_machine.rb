require 'concurrent-edge'

require 'dataset'

module Assets
  class CoffeeMachine < Concurrent::Actor::RestartingContext
    def self.buy_coffee_machines
      Dataset.get.total.coffee_machines.times.map do |i|
        CoffeeMachine.spawn "coffee_machine_#{i}".to_sym
      end
    end
  end
end
