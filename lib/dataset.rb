require 'yaml'

class Dataset
  attr_reader :tables, :total_waiters, :coffee_bar_places

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
    @tables             = data['tables']
    @total_waiters      = data['total waiters']
    @coffee_bar_places  = data['coffee bar places']
  end
end
