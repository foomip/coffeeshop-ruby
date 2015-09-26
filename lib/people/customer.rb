require 'securerandom'
require 'concurrent-edge'

require 'utils/print_message'

module People
  class Customer < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :id, :arrived_at, :seated_at, :stats, :maitre_d, :name
    attr_reader :coffee_bar, :msg_colour, :msg_bgcolour, :identifier

    def self.welcome_customers customer_data, maitre_d, arrival_time
      customer_data = [customer_data] unless customer_data.class == Array

      customer_data.map do |c|
        id = SecureRandom.uuid.gsub '-', ''
        Customer.spawn "custmer_#{id}", id, c, maitre_d, arrival_time
      end
    end

    def initialize id, name, maitre_d, arrival_time
      @id             = id
      @name           = name
      @maitre_d       = maitre_d
      @arrived_at     = arrival_time
      @stats          = {}
      @msg_colour     = :light_green
      @msg_bgcolour   = nil
      @identifier     = "Customer (#{short_name})"
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
      else
        log "WARNING: Customer #{id} received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end

    def at_coffee_bar?
      !coffee_bar.nil?
    end

    def find_seat_at coffee_bar, maitre_d
      if coffee_bar.ask! [:sit_down, self]
        @seated_at = Time.now
        log 'Found myself a seat at the coffee bar'
      else
        maitre_d.tell [:coffee_bar_full, self]
      end
    end
  end
end
