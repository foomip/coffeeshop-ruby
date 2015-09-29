require 'concurrent-edge'
require 'securerandom'

module People
  class Customer < Concurrent::Actor::RestartingContext
    def self.welcome_customers *args
      names, maitre_d, arrival_time, prefer_coffee_bar = args
      prefer_coffee_bar = false if prefer_coffee_bar.nil?

      names.map do |name|
        id = SecureRandom.uuid.gsub '-', ''

        Customer.spawn "customer_#{id}"
      end
    end
  end
end
