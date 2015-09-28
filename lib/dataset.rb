require 'yaml'

require 'utils/variances'

class Dataset
  include Variances

  attr_reader :tables, :total_waiters, :coffee_bar_places
  attr_reader :table_customers, :coffee_bar_customers, :arrival_variance
  attr_reader :seating_variance, :check_for_space_variance
  attr_reader :time_customers_will_wait, :order_wait_time

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
    @speedup_factor             = data['speedup factor']
    @tables                     = data['tables']
    @total_waiters              = data['total waiters']
    @coffee_bar_places          = data['coffee bar places']
    @table_customers            = data['customers']['Table customers']
    @coffee_bar_customers       = data['customers']['Coffee bar customers']
    @arrival_variance           = generate_variance_range data['customers']['Arrival variance']
    @seating_variance           = generate_variance_range data['customers']['Seating time variance']
    @check_for_space_variance   = generate_variance_range data['customers']['Maitre\'D check for space variance']
    @time_customers_will_wait   = generate_variance_range data['customers']['Time customers will wait for table']
    @order_wait_time            = generate_variance_range data['customers']['Time customers will wait for order']
  end
end
