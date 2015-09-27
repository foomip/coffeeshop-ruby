require 'concurrent-edge'

require 'dataset'

module Utils
  module People
    module AwaitingCustomersProcess
      attr_reader :processing_waiting_list

      def have_waiting customers
        customers_waiting << customers.to_h
        log "#{customers.length} #{'customer'.pluralize customers.length} arrived but no suitable seating available, added to waiting list"

        customers.each { |c| c[1].tell [:on_waiting_list] }

        if processing_waiting_list.nil?
          @processing_waiting_list = true
          check_for_waiting_customers
        end
      end

      def check_for_waiting_customers
        Concurrent::ScheduledTask.new check_for_seating_variance.sample do
          tell [:try_seat_waiting_customers]
        end.execute
      end

      def check_for_seating_variance
        @check_for_seating_variance ||= Dataset.get.check_for_space_variance
      end

      def customers_waiting
        @customers_waiting ||= []
      end

      def try_seat_waiting_customers
        if customers_waiting.length > 0 # could be that customers got tired of waiting and left
          customers = customers_waiting.first.values

          if customers.length == 1 && customers[0].ask!([:prefers_coffee_bar]) && !coffee_bar.ask!([:full])
            customers_waiting.delete customers_waiting.first
            customers[0].tell [:find_a_seat, [coffee_bar, self]]

            check_for_waiting_customers
          else
            table = get_table_for customers

            if table
              log "Seating #{customers.length} #{'customer'.pluralize customers.length} (who were waiting) at table #{table.id} (table has #{table.places} #{'place'.pluralize table.places})"
              customers_waiting.delete customers
              table.seat customers
              table.tell_waiter [:customers_seated, table.id]
              customers.each do |v|
                id, c = v
                @customers[id] = c
              end
            else
              log 'No space to seat waiting customers yet, will check again later'
              check_for_waiting_customers
            end
          end
        end
      end

      def tired_of_waiting customer
        stats[:tired_of_waiting] += 1

        customers_waiting.each do |cs|
          cs.delete customer.id
        end

        @customers.delete customer.id

        @customers_waiting = customers_waiting.select { |cs| cs.keys.length > 0 }
      end
    end
  end
end
