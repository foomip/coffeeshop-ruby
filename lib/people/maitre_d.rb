require 'active_support/inflector'
require 'concurrent-edge'

require 'people/customer'
require 'utils/message_printer'
require 'dataset'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
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

    def handle_table_customers names, arrival_time
      total = names.length
      logger.call "#{total} #{'customer'.pluralize total} arrived to be seated"

      customers = People::Customer.welcome_customers names, self.reference, arrival_time
    end

    def handle_coffee_bar_customers name, arrival_time
      logger.call "A customer for the coffee bar arrived"

      customer = People::Customer.welcome_customers([name], self.reference, arrival_time).first
    end
  end
end
