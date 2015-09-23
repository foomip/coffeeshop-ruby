require 'yaml'

require 'utils/variances'

class Dataset
  include Variances

  attr_reader :tables, :total_waiters, :coffee_bar_places
  attr_reader :table_customers, :coffee_bar_customers, :arrival_variance

  def self.get
    if defined? @@data_set
      @@data_set
    else
      @@data_set = load_data
    end
  end

  def self.load_data
    data = YAML.load_file( "#{File.expand_path(File.dirname(__FILE__))}/../dataset.yml" )

    Dataset.new data
  end

  def initialize data
    @speedup_factor       = data['speedup factor']
    @tables               = data['tables']
    @total_waiters        = data['total waiters']
    @coffee_bar_places    = data['coffee bar places']
    @table_customers      = data['customers']['Table customers']
    @coffee_bar_customers = data['customers']['Coffee bar customers']
    @arrival_variance     = generate_variance_range data['customers']['Arrival variance']
  end
end
