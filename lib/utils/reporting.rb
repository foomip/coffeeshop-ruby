require 'active_support/inflector'
require 'terminal-table'

module Utils
  module Reporting
    def print_report_for_the_day
      stats = self.departed_customers.map do |c|
        c.ask! [:get_stats]
      end

      print_customer_summary stats
      print_reasons_for_leaving_summary stats
      print_reasons_for_leaving_summary stats.select { |s| s[:customer_type] == :table },
        'at tables'
      print_reasons_for_leaving_summary stats.select { |s| s[:customer_type] == :coffee_bar },
        'at coffee bar'
      print_drink_types_ordered stats
    end

    private

    def print_customer_summary stats
      rows = [
        ['Total tables', self.tables.length],
        ['Total table seats', self.tables.reduce(0) { |s,t| s + t.ask!( [:get_places] ) }],
        ['Total cofee bar seats', self.coffee_bar.ask!( [:get_places] )],
        ['Total customers', stats.length],
        ['Table customers', stats.select { |s| s[:customer_type] == :table }.length],
        ['Coffee bar customers', stats.select { |s| s[:customer_type] == :coffee_bar }.length]
      ]
      table = Terminal::Table.new title: 'Customer seating summary', rows: rows

      puts table
    end

    def print_reasons_for_leaving_summary stats, label='overall'
      leaving_group = stats.group_by { |s| s[:leaving_reason] }
      rows = leaving_group.keys.sort.map do |key|
        res = "#{leaving_group[key].length} " +
          "(#{"%.2f" % ((leaving_group[key].length.to_f / stats.length.to_f) * 100) }%)"
        [key.capitalize, res]
      end
      table = Terminal::Table.new title: "Reasons for customers leaving (#{label})", rows: rows

      puts table
    end

    def print_drink_types_ordered stats
      drinks_summary = Hash.new 0
      stats.each do |s|
        s[:drinks].each do |d|
          name = d.capitalize
          drinks_summary[name] += 1
        end
      end
      rows = drinks_summary.keys.sort.map do |d|
        [d, drinks_summary[d]]
      end
      table = Terminal::Table.new title: 'Ordered drink summary', rows: rows

      puts table
    end
  end
end
