require 'active_support/inflector'
require 'concurrent-edge'

require 'utils/people_logic/departing_customers'
require 'utils/people_logic/seating_customers'
require 'utils/people_logic/waiting_list'
require 'utils/message_printer'
require 'dataset'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
    include Utils::PeopleLogic::DepartingCustomers
    include Utils::PeopleLogic::SeatingCustomers
    include Utils::PeopleLogic::WaitingList

    attr_reader :logger, :tables, :coffee_bar, :seating_time_variance
    attr_reader :customers, :waiting_customers, :departed_customers
    attr_reader :check_for_space_variance

    def self.hire_maitre_d tables, coffee_bar
      logger                    = message_printer_setup 'Maitre\'D', Dataset.get.colours.maitre_d
      seating_time_variance     = Dataset.get.customers.seating_time_variance
      check_for_space_variance  = Dataset.get.customers.maitre_d_check_for_space_variance

      MaitreD.spawn :maitre_d, logger, tables, coffee_bar, seating_time_variance,
        check_for_space_variance
    end

    def initialize *args
      @logger, @tables, @coffee_bar, @seating_time_variance, @check_for_space_variance = args
      @customers = []
      @waiting_customers = []
      @departed_customers = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customer_arrived
        data, arrival_time = message
        seat_at, customer_names = data

        handle_table_customers customer_names, arrival_time if seat_at == :table
        handle_coffee_bar_customers customer_names, arrival_time if seat_at == :coffee_bar
        return
      when :seated_at_coffee_bar
        customer = message
        self.customers << customer
        return
      when :coffee_bar_full
        customer = message
        assign_table_to [customer]
        return
      when :customer_leaving
        customer = message
        customer_leaving customer
        return
      when :seat_waiting_customers
        seat_waiting_customers
        return
      when :coffeeshop_empty
        !has_customers? && !has_waiting_customers?
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def has_customers?
      self.customers.length > 0
    end

    def has_waiting_customers?
      self.waiting_customers.length > 0
    end
  end
end
