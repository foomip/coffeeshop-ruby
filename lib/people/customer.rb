require 'securerandom'
require 'concurrent-edge'

require 'utils/print_message'
require 'dataset'

module People
  class Customer < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :id, :arrived_at, :seated_at, :stats, :maitre_d, :name
    attr_reader :coffee_bar, :msg_colour, :msg_bgcolour, :identifier
    attr_reader :prefer_coffee_bar, :wait_for_table

    def self.welcome_customers customer_data, maitre_d, arrival_time, prefer_coffee_bar=false
      customer_data = [customer_data] unless customer_data.class == Array

      customer_data.map do |c|
        id = SecureRandom.uuid.gsub '-', ''
        wait_for_table = Dataset.get.time_customers_will_wait

        customer = Customer.spawn "customer_#{id}", id, c, maitre_d, arrival_time,
          prefer_coffee_bar, wait_for_table

        [id, customer]
      end
    end

    def initialize *args
      @id, @name, @maitre_d, @arrived_at, @prefer_coffee_bar, @wait_for_table = args
      @stats              = {}
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
      when :find_a_seat
        coffee_bar, maitre_d = message
        find_seat_at coffee_bar, maitre_d
      when :on_waiting_list
        Concurrent::ScheduledTask.new wait_for_table.sample do
          tell [:tired_of_waiting_reached]
        end.execute
        nil
      when :tired_of_waiting_reached
        if seated_at.nil?
          stats[:time_left] = Time.now
          stats[:served] = false
          self.maitre_d.tell [:tired_of_waiting, self]
        end
        nil
      when :prefers_coffee_bar
        prefers_coffee_bar?
      else
        log "WARNING: Customer #{id} received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def at_coffee_bar?
      !coffee_bar.nil?
    end

    def prefers_coffee_bar?
      prefer_coffee_bar
    end

    def find_seat_at coffee_bar, maitre_d
      if coffee_bar.ask! [:sit_down, self]
        @seated_at = Time.now
        log 'Found myself a seat at the coffee bar'
        :found_a_seat
      else
        :coffee_bar_full
      end
    end
  end
end
