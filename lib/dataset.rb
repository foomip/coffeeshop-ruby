require 'yaml'

require 'utils/variances'

class Dataset
  include Utils::Variances

  attr_reader :log_level, :speedup_factor, :colours, :customers, :total, :tables
  attr_reader :drinks

  def self.get
    if defined? @@data_set
      @@data_set
    else
      @@data_set = load_data
    end
  end

  def self.load_data
    data = YAML.load_file( "#{File.expand_path(File.dirname(__FILE__))}/../dataset.yml" )

    Dataset.new(data).freeze
  end

  def initialize data
    @log_level        = data['log level']
    @speedup_factor   = data['speedup factor']
    @colours          = colours_struct.new(
      data['colours']['customer'].to_sym,
      data['colours']['maitre_d'].to_sym,
      data['colours']['coffee_bar'].to_sym,
      data['colours']['barista'].to_sym,
      data['colours']['waiter'].to_sym,
      data['colours']['table'].to_sym
    )
    @customers        = customers_struct.new(
      generate_variance_range( data['customers']['Seating time variance'] ),
      generate_variance_range( data['customers']['Arrival variance'] ),
      data['customers']['Table customers'],
      data['customers']['Coffee bar customers'],
      generate_variance_range( data['customers']['Time waiters will take to engage customers'] ),
      generate_variance_range( data['customers']['Time customers will wait for seating'] ),
      generate_variance_range( data['customers']['Maitre\'D check for space variance'] ),
      generate_variance_range( data['customers']['Orders per customer'] ),
      generate_variance_range( data['customers']['Time customers will wait for order to arrive'] ),
      generate_variance_range( data['customers']['Amount of time between checking on customers'] )
    )
    @total            = total_struct.new(
      data['total waiters'],
      data['total baristas'],
      data['total coffee machines'],
      data['total coffee bar places']
    )
    @tables           = data['tables']
    @drinks           = data['drinks'].map do |d|
      d.keys.reduce({}) do |x, k|
        x[k.to_sym] = d[k]
        x
      end
    end
  end

  def customers_struct
    @customers_struct ||= Struct.new :seating_time_variance, :arrival_variance,
      :table_customers, :coffee_bar_customers, :waiters_engage_customers_variance,
      :customer_wait_for_seating_variance, :maitre_d_check_for_space_variance,
      :orders_per_customer_variance, :wait_for_order_arrival_variance,
      :check_on_customers_variance
  end

  def colours_struct
    @colours_struct ||= Struct.new :customer, :maitre_d, :coffee_bar, :barista,
      :waiter, :table
  end

  def total_struct
    @total_struct ||= Struct.new :waiters, :baristas, :coffee_machines,
      :coffee_bar_places
  end
end
