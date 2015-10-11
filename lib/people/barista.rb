require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module People
  class Barista < Concurrent::Actor::RestartingContext
    attr_reader :logger, :coffee_machines, :coffee_bar, :order_check_variance
    attr_reader :coffee_machine_availability_variance

    def self.hire_baristas coffee_machines
      order_check_variance = Dataset.get.customers.barista_order_check_variance
      coffee_machine_availability_variance = Dataset.get.customers.barista_coffee_machine_availability_variance

      Dataset.get.total.baristas.times.map do |i|
        logger = message_printer_setup "Barista #{i}", Dataset.get.colours.barista

        Barista.spawn "barista_#{i}".to_sym, logger, coffee_machines, order_check_variance,
          coffee_machine_availability_variance
      end
    end

    def initialize *args
      @logger, @coffee_machines, @order_check_variance, @coffee_machine_availability_variance = args
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :coffee_bar_ready
        @coffee_bar = message
        run_checking_for_orders
        return
      when :check_for_orders
        if [true,false].sample then tables_prioritise else coffee_bar_prioritise end
        run_checking_for_orders
        return
      when :have_coffee_machine
        coffee_machine, order_type, order = message
        create_order coffee_machine, order_type, order
        return
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def coffee_bar_prioritise
      handle_coffee_bar_orders && handle_table_orders && no_waiting_orders
    end

    def tables_prioritise
      handle_table_orders && handle_coffee_bar_orders && no_waiting_orders
    end

    def no_waiting_orders
      logger.call 'No waiting orders, will check again later'
    end

    def handle_table_orders
      table_order = coffee_bar.ask! [:get_table_order]

      if table_order
        run_try_create_order :table, table_order
        false
      else
        true
      end
    end

    def handle_coffee_bar_orders
      print "TODO: handle orders for customers at coffee bar\n".red
      true
    end

    def create_order coffee_machine, order_type, order
      create_table_order coffee_machine, order if order_type == :table
      create_coffee_bar_order coffee_machine, order if order_type == :coffee_bar
    end

    def create_table_order coffee_machine, order
      completed_orders = order.orders.map do |o|
        order_info, customer = o

        # so blocking a thread like this is considered bad practice
        # we are just simulating the barista doing work, creating the
        # order. Don't do this in real life production apps
        sleep order_info[:preparation_variance].sample

        [order_info[:name], customer]
      end

      table_id = order.table.ask! [:get_id]
      logger.call "Finished making order for table #{table_id}"

      coffee_machine.tell [:i_am_done, self.reference]
      order.waiter.tell [:order_ready_to_serve, [completed_orders, order.table]]
    end

    def create_coffee_bar_order coffee_machine, order

    end

    def run_try_create_order order_type, order
      Concurrent::ScheduledTask.new(coffee_machine_availability_variance.sample) do
        machine = coffee_machines.find do |coffee_machine|
          coffee_machine.ask! [:need_to_use_you, self.reference]
        end

        if machine
          logger.call 'Managed to get hold of a coffe machine to create order'
          self.reference.tell [:have_coffee_machine, [machine, order_type, order]]
        else
          run_try_create_orders order_type, orders
        end
      end.execute
    end

    def run_checking_for_orders
      Concurrent::ScheduledTask.new(order_check_variance.sample) do
        self.reference.tell [:check_for_orders]
      end.execute
    end
  end
end
