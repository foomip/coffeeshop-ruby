require 'concurrent-edge'
require 'securerandom'

require 'utils/message_printer'

module People
  class Customer < Concurrent::Actor::RestartingContext
    attr_reader :logger, :id, :stats, :table_id

    def self.welcome_customers *args
      names, maitre_d, arrival_time, prefer_coffee_bar = args
      prefer_coffee_bar = false if prefer_coffee_bar.nil?

      names.map do |name|
        id      = SecureRandom.uuid.gsub '-', ''
        logger  = message_printer_setup "Customer (#{name})", Dataset.get.colours.customer

        Customer.spawn "customer_#{id}", logger, id
      end
    end

    def initialize *args
      @logger, @id = args

      @stats = Hash.new 0

      stats[:arrived_at] = Time.now
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :seated_at
        @table_id = message
        stats[:seated_at] = Time.now
        nil
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        nil
      end
    end
  end
end
