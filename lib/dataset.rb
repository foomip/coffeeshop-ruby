require 'yaml'

require 'utils/variances'

class Dataset
  include Utils::Variances

  attr_reader :speedup_factor, :colours, :customers, :total

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
    @speedup_factor   = data['speedup factor']
    @colours          = colours_struct.new(
      data['colours']['customers'].to_sym,
      data['colours']['maitre_d'].to_sym,
      data['colours']['coffee_bar'].to_sym,
      data['colours']['barista'].to_sym
    )
    @customers        = customers_struct.new(
      generate_variance_range( data['customers']['Arrival variance'] )
    )
    @total            = total_struct.new(
      data['total waiters'],
      data['total baristas'],
      data['total coffee machines'],
      data['total coffee bar places']
    )
  end

  def customers_struct
    @customers_struct ||= Struct.new :arrival_variance
  end

  def colours_struct
    @colours_struct ||= Struct.new :customers, :maitre_d, :coffee_bar, :barista
  end

  def total_struct
    @total_struct ||= Struct.new :waiters, :baristas, :coffee_machines,
      :coffee_bar_places
  end
end
