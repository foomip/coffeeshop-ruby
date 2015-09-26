require 'dataset'

module Assets
  class Table
    attr_reader :id, :places, :customers, :waiter

    def self.build_tables
      i = 0
      Dataset.get.tables.flat_map do |data|
        data['total'].times.map do
          table = Table.new i, data['places']
          i += 1
          table
        end
      end
    end

    def initialize id, places
      @id         = id
      @places     = places
      @customers  = []
      @waiter     = nil
    end

    def has_waiter?
      not @waiter.nil?
    end

    def tell_waiter msg
      waiter.tell msg if has_waiter?
    end

    def waiter_is waiter
      @waiter = waiter
    end

    def occupied?
      customers.length > 0
    end

    def seat cs
      cs = [cs] unless cs.class == Array

      cs.each do |c|
        c.tell [:seated, id]
        @customers << c
      end
    end
  end
end
