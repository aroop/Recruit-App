module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalExpressReferenceNvResponse < PaypalExpressNvResponse
      def token
        @params['billingagreementid'] || @params['token']
      end
    end
  end
end