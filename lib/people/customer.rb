require 'securerandom'
require 'concurrent-edge'

require 'utils/print_message'
require 'dataset'

module People
  class Customer < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :id, :arrived_at, :seated_at, :stats, :maitre_d, :name
    attr_reader :coffee_bar, :msg_colour, :msg_bgcolour, :identifier
    attr_reader :prefer_coffee_bar, :wait_for_table, :order_wait_time

    def self.welcome_customers customer_data, maitre_d, arrival_time, prefer_coffee_bar=false
      customer_data = [customer_data] unless customer_data.class == Array

      customer_data.map do |c|
        id = SecureRandom.uuid.gsub '-', ''
        wait_for_table  = Dataset.get.time_customers_will_wait
        order_wait_time = Dataset.get.order_wait_time

        customer = Customer.spawn "customer_#{id}", id, c, maitre_d, arrival_time,
          prefer_coffee_bar, wait_for_table, order_wait_time

        [id, customer]
      end
    end

    def initialize *args
      @id, @name, @maitre_d, @arrived_at, @prefer_coffee_bar, @wait_for_table,
      @order_wait_time = args

      @stats              = Hash.new 0
      @msg_colour         = :light_green
      @msg_bgcolour       = nil
      @identifier         = "Customer (#{short_name})"
    end

    def short_name
      first, last = name.split(' ')
      "#{first} #{last[0]}."
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :seated
        @seated_at = Time.now
        ready_to_place_order
        nil
      when :find_a_seat
        coffee_bar = message
        find_seat_at coffee_bar
      when :on_waiting_list
        Concurrent::ScheduledTask.new wait_for_table.sample do
          if seated_at.nil?
            log "Tired of waiting for a table, leaving the coffee shop"
            stats[:time_left] = Time.now
            stats[:served] = false
            stats[:leaving_reason] = 'Waited too long to be seated, no service'
            tell [:tired_of_waiting_reached]
          end
        end.execute
        nil
      when :tired_of_waiting_reached
        self.maitre_d.tell [:tired_of_waiting, self]
        nil
      when :feedback
        stats
      when :prefers_coffee_bar
        prefer_coffee_bar
      else
        log "WARNING: Customer #{id} received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def at_coffee_bar?
      !coffee_bar.nil?
    end

    def find_seat_at coffee_bar
      if coffee_bar.ask! [:sit_down, self.reference]
        @seated_at = Time.now
        @coffee_bar = coffee_bar
        log 'Found myself a seat at the coffee bar'
        ready_to_place_order true
        :found_a_seat
      else
        :coffee_bar_full
      end
    end

    def ready_to_place_order at_coffee_bar=false
      coffee_bar.tell [:ready_to_place_order, self.reference] if at_coffee_bar

      @order_waiting_timer = Concurrent::ScheduledTask.new order_wait_time.sample do
        log 'Tired of waiting to be served, leaving coffee shop'
        stats[:leaving_reason] = 'Waited too long to order, no service'
        tell [:tired_of_waiting_reached]
      end

      @order_waiting_timer.execute
    end
  end
end
