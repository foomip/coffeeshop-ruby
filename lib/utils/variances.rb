require 'gsl'
require 'distribution'

module Utils
  module Variances
    def variance_object
      @variance_object ||= Struct.new :proc, :speedup_factor do
        def sample
          sample = proc.call / speedup_factor
          sample > 0 ? sample : 0.01
        end
      end
    end

    def randomness
      @randomness ||= Random.new
    end

    def generate_variance_range variances
      min           = variances['min']
      max           = variances['max']
      median        = variances.has_key?('median') ? variances['median'] : min + ((max - min) / 2)
      sigma         = 4 # hard coded for now, seems like a good sane default
      min_range     = min - median + 1
      max_range     = max - median - 1

      rnd_proc = Distribution::Normal.rng(median, sigma, randomness.rand(min_range..max_range))
      variance_object.new rnd_proc, @speedup_factor
    end
  end
end
