module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalReferenceNvResponse < Response
      def token
        authorization
      end
    end
  end
end