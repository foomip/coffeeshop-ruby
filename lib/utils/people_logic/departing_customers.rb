module Utils
  module PeopleLogic
    module DepartingCustomers
      def customer_leaving customer
        @customers.delete customer

        @waiting_customers.each { |cs| cs.delete customer }
        @waiting_customers = @waiting_customers.select { |cs| cs.length != 0 }

        @departed_customers << customer
      end
    end
  end
end
