require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module Assets
  class CoffeeMachine < Concurrent::Actor::RestartingContext
    attr_reader :logger, :allocated_to

    def self.buy_coffee_machines
      Dataset.get.total.coffee_machines.times.map do |i|
        logger = message_printer_setup "Coffee Machine #{i}", Dataset.get.colours.coffee_bar

        CoffeeMachine.spawn "coffee_machine_#{i}".to_sym, logger
      end
    end

    def initialize logger
      @logger = logger
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :need_to_use_you
        if is_allocated?
          false
        else
          @allocated_to = message
          true
        end
      when :i_am_done
        user = message
        if @allocated_to == user
          @allocated_to = nil
        else
          logger.call "Asked to deallocate myself by the wrong person? #{user}"
        end
        return
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def is_allocated?
      !allocated_to.nil?
    end
  end
end
