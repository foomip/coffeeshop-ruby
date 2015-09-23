require 'dataset'

module Assets
  class Table
    attr_reader :id, :places, :occupied, :waiter

    def self.build_tables
      Dataset.get.tables.flat_map do |data|
        data['total'].times.map do |i|
          Table.new i, data['places']
        end
      end
    end

    def initialize id, places
      @id       = id
      @places   = places
      @occupied = false
    end

    def has_waiter?
      not @waiter.nil?
    end

    def waiter_is waiter
      @waiter = waiter
    end
  end
end
