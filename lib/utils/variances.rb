module Utils
  module Variances
    def generate_variance_range variances
      (variances['min']..variances['max']).map do |i|
        i.to_f / @speedup_factor
      end
    end
  end
end
