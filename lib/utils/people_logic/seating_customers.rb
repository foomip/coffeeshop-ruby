require 'active_support/inflector'
require 'concurrent-edge'

require 'people/customer'
require 'utils/message_printer'

module Utils
  module PeopleLogic
    module SeatingCustomers
      def handle_table_customers names, arrival_time
        total = names.length
        logger.call "#{total} #{'customer'.pluralize total} arrived to be seated", LOG_LEVEL.debug

        customers = People::Customer.welcome_customers names, self.reference, arrival_time

        assign_table_to customers
      end

      def handle_coffee_bar_customers name, arrival_time
        logger.call "A customer for the coffee bar arrived", LOG_LEVEL.debug

        customer = People::Customer.welcome_customers([name], self.reference, arrival_time, true).first

        send_to_coffee_bar customer, arrival_time
      end

      def assign_table_to customers
        # simulate variable time taken to get customers seated
        Concurrent::ScheduledTask.new(seating_time_variance.sample) do
          if waiting_customers.length > 0
            add_to_waiting_list customers
          else
            table = get_table_for customers

            if table
              seat_customers_at table, customers
            else
              add_to_waiting_list customers
            end
          end
        end.execute.wait # <<< BAD
      end

      def get_table_for customers
        total = customers.length

        tables.select do |t|
          t.ask! [:can_seat, total]
        end.sort do |left, right|
          left_places = left.ask! [:get_places]
          right_places = right.ask! [:get_places]

          left_places <=> right_places
        end.first
      end

      def show_customers_to table, customers
        table.tell [:seat_customers, customers]
      end

      def send_to_coffee_bar customer, arrival_time
        customer.tell [:find_a_seat, coffee_bar]
      end

      def seat_customers_at table, customers
        table_id      = table.ask! [:get_id]
        table_places  = table.ask! [:get_places]

        logger.call "Seating #{customers.length} #{'customer'.pluralize customers.length} " +
          "at table #{table_id} (table has #{table_places} #{'place'.pluralize table_places})"

        show_customers_to table, customers

        @customers += customers
      end
    end
  end
end
