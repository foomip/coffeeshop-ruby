require 'concurrent-edge'

require 'dataset'
require 'utils/message_printer'

module Assets
  class Table < Concurrent::Actor::RestartingContext
    attr_reader :logger, :id, :places, :waiter, :customers

    def self.build_tables
      index = 0
      Dataset.get.tables.flat_map do |data|
        data['total'].times.map do
          logger  = message_printer_setup "Table #{index}", Dataset.get.colours.table
          table   = Table.spawn "table_#{index}".to_sym, logger, index, data['places']

          index += 1
          table
        end
      end
    end

    def initialize *args
      @logger, @id, @places = args
      @customers = []
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :i_am_your_father
        @waiter, id = message
        waiter.tell [:customers_seated, [id, self.reference]] if occupied?
        nil
      when :get_id
        self.id
      when :can_seat
        !occupied? && places >= message
      when :get_places
        places
      when :seat_customers
        @customers = message
        waiter.tell [:customers_seated, [id, self.reference]] if has_waiter?
        nil
      else
        logger.call "Received message of type #{msg_type}: #{message} - don't know what to do??", LOG_LEVEL.warn
        nil
      end
    end

    def occupied?
      @customers.length > 0
    end

    def has_waiter?
      !waiter.nil?
    end
  end
end
