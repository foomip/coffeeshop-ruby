require 'concurrent-edge'

module Assets
  class CoffeeMachine < Concurrent::Actor::RestartingContext
    attr_reader :steamer_in_use, :coffee_maker_in_use

    def initialize
      @steamer_in_use       = false
      @coffee_maker_in_use  = false
    end
  end
end
