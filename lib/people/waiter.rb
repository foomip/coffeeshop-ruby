require 'active_support/inflector'
require 'colorize'
require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module People
  class Waiter < Concurrent::Actor::RestartingContext
    attr_reader :logger, :id, :tables, :engage_customers_variance, :check_on_customers_variance
    attr_reader :coffee_bar

    def self.hire_waiters tables, coffee_bar
      engage_customers_variance   = Dataset.get.customers.waiters_engage_customers_variance
      check_on_customers_variance = Dataset.get.customers.check_on_customers_variance
      total_waiters               = Dataset.get.total.waiters

      if total_waiters > tables.length
        puts 'WARNING: simulation run has more waiters than tables'.red
      end

      tables.zip((0...total_waiters).to_a.lazy.cycle).group_by { |x| x[1] }.map do |y|
        id = y[0]
        tables = y[1].map { |x| x[0]  }
        logger = message_printer_setup "Waiter #{id}", Dataset.get.colours.waiter

        Waiter.spawn "waiter_#{id}".to_sym, logger, id, tables, engage_customers_variance,
          check_on_customers_variance, coffee_bar
      end
    end

    def initialize *args
      @logger, @id, @tables, @engage_customers_variance, @check_on_customers_variance,
        @coffee_bar = args

      own_tables
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customers_seated
        table_id, table = message
        simulate_welcome_wait table_id, table
        return
      when :welcome_customers
        table_id, table = message
        logger.call "Welcoming customers at table #{table_id}"
        ask_customers_for_order table_id, table
        return
      when :check_on_customers
        table = message
        table_id = table.ask! [:get_id]
        ask_customers_for_order table_id, table
        return
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def own_tables
      tables.each do |t|
        t.tell [:i_am_your_father, [self.reference, id]]

        table_id = t.ask! [:get_id]
        logger.call "Now in charge of table id #{table_id}"
      end
    end

    def simulate_welcome_wait table_id, table
      Concurrent::ScheduledTask.new(engage_customers_variance.sample) do
        self.reference.tell [:welcome_customers, [table_id, table]]
      end.execute
    end

    def ask_customers_for_order table_id, table
      if table.ask! [:has_customers]
        logger.call "Checking on customers at table #{table_id}"
        customers = table.ask! [:get_customers]

        orders = customers.reduce([]) do |os, c|
          order = c.ask! [:what_would_you_like]

          os << order unless order.nil?
          os
        end

        if orders.length > 0
          logger.call "Need to place #{orders.length} #{'order'.pluralize orders.length} with coffee bar"

          coffee_bar.tell [:place_table_order, [orders, table, self.reference]]

          run_check_back_on_customers table
        else
          logger.call "No orders from table #{table_id} - will ask again later"
          run_check_back_on_customers table
        end
      else
        logger.call "No more customers to serve a table #{table_id}"
      end
    end

    def run_check_back_on_customers table
      Concurrent::ScheduledTask.new(check_on_customers_variance.sample) do
        self.reference.tell [:check_on_customers, table]
      end.execute
    end
  end
end
