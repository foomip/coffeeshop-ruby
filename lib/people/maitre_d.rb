require 'concurrent-edge'
require 'active_support/inflector'

require 'dataset'
require 'utils/print_message'
require 'utils/people/awaiting_customers_process'
require 'people/customer'

module People
  class MaitreD < Concurrent::Actor::RestartingContext
    include PrintMessage
    include Utils::People::AwaitingCustomersProcess

    attr_reader :tables, :msg_colour, :msg_bgcolour, :identifier
    attr_reader :seating_variance, :coffee_bar, :stats

    def self.hire_maitre_d tables, coffee_bar
      MaitreD.spawn :maitre_d, tables, coffee_bar, Dataset.get.seating_variance
    end

    def initialize tables, coffee_bar, seating_variance
      @tables             = tables
      @coffee_bar         = coffee_bar
      @seating_variance   = seating_variance
      @identifier         = "Maitre'D"
      @msg_colour         = :light_blue
      @msg_bgcolour       = :default
      @customers          = {}
      @stats              = Hash.new 0
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customer_arrived
        seat_customer message
        nil
      when :try_seat_waiting_customers
        try_seat_waiting_customers
        nil
      when :tired_of_waiting
        customer = message
        tired_of_waiting customer
        nil
      when :coffeeshop_empty
        @customers.keys.length == 0 && customers_waiting.length == 0
      else
        log "WARNING: Maitre D received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def seat_customer data
      cust_data, arrival_time = data
      seat_at, customers      = cust_data

      if seat_at == :table
        seat_customers customers, arrival_time
      else
        send_to_coffee_bar customers, arrival_time
      end
    end

    def seat_customers data, arrival_time
      customers = Customer.welcome_customers data, self, arrival_time

      assign_table_to customers
    end

    def assign_table_to customers
      # simulate variable time taken to get customers seated
      sleep seating_variance.sample

      if customers_waiting.length > 0
        have_waiting customers
      else
        table = get_table_for customers

        if table
          log "Seating #{customers.length} #{'customer'.pluralize customers.length} at table #{table.id} (table has #{table.places} #{'place'.pluralize table.places})"
          show_customers_to_table table, customers
        else
          have_waiting customers
        end
      end
    end

    def show_customers_to_table table, customers
      table.seat customers
      table.tell_waiter [:customers_seated, table.id]
      customers.each do |v|
        id, c = v
        @customers[id] = c
      end
    end

    def send_to_coffee_bar data, arrival_time
      id, customer = Customer.welcome_customers(data, self, arrival_time, true).first

      case customer.ask! [:find_a_seat, coffee_bar, self]
      when :coffee_bar_full
        customers = [[id, customer]]
        assign_table_to customers
      when :found_a_seat
        @customers[id] = customer
      end
    end

    def get_table_for customers
      total     = customers.length

      tables.select do |t|
        !t.occupied? && t.places >= total

      end.sort do |left, right|
        (left.places - total) <=> (right.places - total)
      end.first
    end
  end
end
