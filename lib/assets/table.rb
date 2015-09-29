require 'concurrent-edge'

require 'dataset'

module Assets
  class Table < Concurrent::Actor::RestartingContext
    attr_reader :id, :places

    def self.build_tables
      index = 0
      Dataset.get.tables.flat_map do |data|
        table = Table.spawn "table_#{index}".to_sym, index, data['places']
        index += 1
        table
      end
    end

    def initialize id, places
      @id       = id
      @places   = places
    end
  end
end
