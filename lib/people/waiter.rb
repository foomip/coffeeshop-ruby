require 'concurrent-edge'
require 'colorize'

require 'dataset'
require 'utils/streamer'

module People
  class Waiter < Concurrent::Actor::RestartingContext
    include PrintMessage

    attr_reader :id, :tables, :msg_colour, :msg_bgcolour, :identifier

    def self.hire_waiters tables
      total_waiters = Dataset.get.total_waiters

      if total_waiters > tables.length
        puts 'WARNING: simulation run has more waiters than tables'.red
      end

      # create an enumerator that will stream waiter number contunuously
      waiter_stream = Streamer.new (0...total_waiters).to_a

      tables.zip(waiter_stream.lazy).group_by { |x| x[1] }.map do |y|
        id = y[0]
        tables = y[1].map { |x| x[0] }

        Waiter.spawn "waiter_#{id}".to_sym, id, tables
      end
    end

    def initialize id, tables
      @id             = id
      @tables         = tables
      @msg_colour     = :light_yellow
      @msg_bgcolour   = nil
      @identifier     = "Waiter #{id}"

      add_waiter_references
    end

    def add_waiter_references
      @tables.each { |t| t.waiter_is self }
    end

    def on_message msg
      msg_type, message = msg

      case msg_type
      when :customers_seated
        log "Saw customers seated at table #{message}, engaging customers to take order"
      else
        log "WARNING: Waiter received message of type #{msg_type}: #{message} - don't know what to do??"
      end
    end
  end
end
