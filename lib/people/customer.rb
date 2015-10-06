require 'colorize'
require 'concurrent-edge'
require 'securerandom'

require 'dataset'
require 'utils/message_printer'

module People
  class Customer < Concurrent::Actor::RestartingContext
    attr_reader :logger, :id, :stats, :table_id, :wait_for_seating_variance
    attr_reader :maitre_d, :prefer_coffee_bar, :total_orders, :drinks
    attr_reader :wait_for_order_arrival_variance, :status

    def self.welcome_customers *args
      names, maitre_d, arrival_time, prefer_coffee_bar = args
      prefer_coffee_bar = false if prefer_coffee_bar.nil?
      drinks            = Dataset.get.drinks

      wait_for_seating_variance = Dataset.get.customers.customer_wait_for_seating_variance
      wait_for_order_arrival_variance = Dataset.get.customers.wait_for_order_arrival_variance

      names.map do |name|
        id            = SecureRandom.uuid.gsub '-', ''
        logger        = message_printer_setup "Customer (#{name})#{if prefer_coffee_bar then " CB" else "" end}",
                          Dataset.get.colours.customer
        total_orders  = Dataset.get.customers.orders_per_customer_variance.sample

        Customer.spawn "customer_#{id}", logger, id, wait_for_seating_variance,
          maitre_d, prefer_coffee_bar, total_orders, drinks, wait_for_order_arrival_variance
      end
    end

    def initialize *args
      @logger, @id, @wait_for_seating_variance, @maitre_d, @prefer_coffee_bar,
      @total_orders, @drinks, @wait_for_order_arrival_variance = args

      @stats = {total_orders: 0, times_asked_for_order: 0}
      @status = :waiting_for_seat

      stats[:arrived_at] = Time.now

      run_waiting_for_table
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :seated
        unless already_left?
          @table = message
          got_a_seat
        end
        return
      when :find_a_seat
        unless already_left?
          coffee_bar = message
          try_sit_at_coffee_bar coffee_bar
        end
        return
      when :leaving
        @table.tell [:customer_leaving, self.reference] unless @table.nil?
        maitre_d.tell [:customer_leaving, self.reference]
        return
      when :prefer_coffee_bar
        prefer_coffee_bar
      when :what_would_you_like
        if currently_busy_with_drink?
          nil
        else
          maybe_place_order
        end
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        return
      end
    end

    def already_left?
      !stats[:leaving_reason].nil?
    end

    def still_want_to_order?
      stats[:total_orders] < total_orders
    end

    def ready_to_order?
      [true, false, true].sample
    end

    def currently_busy_with_drink?
      [:waiting_for_order, :drinking].include? status
    end

    def maybe_place_order
      stats[:times_asked_for_order] += 1
      if !already_left? && still_want_to_order? && ready_to_order?
        order = drinks.sample
        @status = :waiting_for_order

        logger.call "Placing order with waiter - #{order[:name]}"
        run_waiting_for_order_to_arrive
        [order, self.reference]
      else
        run_waiting_to_be_served
        nil
      end
    end

    def try_sit_at_coffee_bar coffee_bar
      if coffee_bar.ask! [:give_me_a_seat, self.reference]
        got_a_seat
        maitre_d.tell [:seated_at_coffee_bar, self.reference]
        run_waiting_to_be_served
      else
        logger.call "No seats available at the coffee bar, will try get a table"
        maitre_d.tell [:coffee_bar_full, self.reference]
      end
    end

    def got_a_seat
      stats[:seated_at] = Time.now
      @status = :seated

      run_waiting_to_be_served
    end

    def run_waiting_for_table
      Concurrent::ScheduledTask.new(wait_for_seating_variance.sample) do
        if stats[:seated_at].nil?
          logger.call 'Tired of waiting for a seat, I\'m leaving now'
          stats[:leaving_reason] = 'Waited too long for a seat'

          self.reference.tell [:leaving]
        end
      end.execute
    end

    def run_waiting_to_be_served
      times_asked = stats[:times_asked_for_order]

      Concurrent::ScheduledTask.new(wait_for_seating_variance.sample) do
        if times_asked == stats[:times_asked_for_order]
          logger.call 'Tired of waiting to be served, I\'m leaving now'
          stats[:leaving_reason] = 'Waited too long to place an order'

          self.reference.tell [:leaving]
        end
      end.execute
    end

    def run_waiting_for_order_to_arrive
      total_orders = stats[:total_orders]

      Concurrent::ScheduledTask.new(wait_for_order_arrival_variance.sample) do
        if total_orders == stats[:total_orders]
          logger.call 'Order taking too long to arrive, I\'m leaving now'
          stats[:leaving_reason] = 'Waited too long for order to arrive'

          self.reference.tell [:leaving]
        end
      end.execute
    end
  end
end
