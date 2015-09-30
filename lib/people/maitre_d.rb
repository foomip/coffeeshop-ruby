require 'active_support/inflector'
require 'concurrent-edge'

require 'utils/people_logic/seating_customers'
require 'utils/message_printer'
require 'dataset'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
    include Utils::PeopleLogic::SeatingCustomers

    attr_reader :logger, :tables, :coffee_bar, :seating_time_variance
    attr_reader :customers, :waiting_customers

    def self.hire_maitre_d tables, coffee_bar
      logger                = message_printer_setup 'Maitre\'D', :light_blue
      seating_time_variance = Dataset.get.customers.seating_time_variance

      MaitreD.spawn :maitre_d, logger, tables, coffee_bar, seating_time_variance
    end

    def initialize *args
      @logger, @tables, @coffee_bar, @seating_time_variance = args
      @customers = []
      @waiting_customers = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customer_arrived
        data, arrival_time = message
        seat_at, customer_names = data

        handle_table_customers customer_names, arrival_time if seat_at == :table
        handle_coffee_bar_customers customer_names, arrival_time if seat_at == :coffee_bar
        nil
      when :coffeeshop_empty
        false
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        nil
      end
    end
  end
end
