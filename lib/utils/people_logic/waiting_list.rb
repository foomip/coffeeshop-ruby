require 'active_support/inflector'
require 'concurrent-edge'

module Utils
  module PeopleLogic
    module WaitingList
      attr_reader :checking_waiting_list

      def add_to_waiting_list customers
        self.waiting_customers << customers

        total = customers.length
        logger.call "#{total} #{'customer'.pluralize total} arrived but no suitable seating available, added to waiting list"

        unless checking_waiting_list
          @checking_waiting_list = true
          run_seat_waiting_customers
        end
      end

      def run_seat_waiting_customers
        Concurrent::ScheduledTask.new(check_for_space_variance.sample) do
          if self.waiting_customers.length > 0
            self.reference.tell [:seat_waiting_customers]
          else
            @checking_waiting_list = false
          end
        end.execute
      end

      def seat_waiting_customers
        if self.waiting_customers.length > 0
          customers = self.waiting_customers.first

          if customers.length == 1 && customers[0].ask!( [:prefer_coffee_bar] ) &&
            coffee_bar.ask!( [:has_places_available] )

            customers[0].tell [:find_a_seat, coffee_bar]
            self.waiting_customers.delete customers

            logger.call 'Managed to seat 1 waiting customer at the coffee bar'
          else
            table = get_table_for customers

            if table
              seat_customers_at table, customers
            else
              logger.call 'No seating available yet to seat waiting customers'
            end
          end
        end
      end
    end
  end
end
