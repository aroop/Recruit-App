require File.dirname(__FILE__) + '/paypal_nv/paypal_nv_common_api'
require File.dirname(__FILE__) + '/paypal_nv/paypal_express_nv_response'
require File.dirname(__FILE__) + '/paypal_nv/paypal_express_reference_nv_response'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaypalExpressReferenceNvGateway < Gateway
      include PaypalNvCommonAPI

      self.supported_countries = ['US']

      LIVE_REDIRECT_NV_URL = 'https://www.paypal.com/cgibin/webscr?cmd=_customer-billing-agreement&token='
      TEST_REDIRECT_NV_URL = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_customer-billing-agreement&token='

      self.homepage_url = 'https://www.paypal.com/cgi-bin/webscr?cmd=xpt/merchant/ExpressCheckoutIntro-outside'
      self.display_name = 'PayPal Express Checkout for Reference Transactions'

      def redirect_url
        test? ? TEST_REDIRECT_NV_URL : LIVE_REDIRECT_NV_URL
      end

      def redirect_url_for(token, options = {})
        options = {:review => true}.update(options)
        options[:review] ? "#{redirect_url}#{token}" : "#{redirect_url}#{token}&useraction=commit"
      end

      def setup_authorization(options = {})
        requires!(options, :return_url, :cancel_return_url)
        post = {}
        add_pair(post, :returnurl, options[:return_url])
        add_pair(post, :cancelurl, options[:cancel_return_url])
        add_pair(post, :billingtype, 'MerchantInitiatedBilling')
        add_pair(post, :billingagreementdescription, options[:description]) if options[:description]
        add_pair(post, :billingagreementcustom, options[:custom]) if options[:custom]
        add_pair(post, :paymenttype, options[:payment_type]) if options[:payment_type]
        commit 'SetCustomerBillingAgreement', post.merge(build_payment_pages(options))
      end

      alias_method :setup_purchase, :setup_authorization

      def details_for(token)
        commit 'GetBillingAgreementCustomerDetails', :token => token
      end

      def authorize(money, reference_id, options = {})
        add_pair(options, :referenceid, reference_id)
        commit 'DoReferenceTransaction', build_sale_or_authorization_request('Authorization', money, options.merge(:reference_id => reference_id))
      end

      def purchase(money, reference_id, options = {})
        commit 'DoReferenceTransaction', build_sale_or_authorization_request('Sale', money, options.merge(:reference_id => reference_id))
      end
      
      def create_billing_agreement_for(token)
        post = {}
        add_pair(post, :token, token)
        commit 'CreateBillingAgreement', post
      end
      
      def unstore(reference_id)
        # no-op
      end
      
      private
      
      def build_sale_or_authorization_request(action, money, options)
        post = {}
        #required
        add_pair(post, :paymentaction, action)
        add_pair(post, :referenceid, options[:reference_id])
        add_amount(post, money, options)
        add_pair(post, :buttonsource, application_id)

        # optional
        add_pair(post, :currencycode, options[:currency] || "USD")

        post
      end
      
      # All optional.  Used with setting up billing agreements and express checkout
      def build_payment_pages(options)
        post = {}
        add_pair(post, :localecode, options[:locale_code]) if options[:locale_code]
        add_pair(post, :pagestyle, options[:page_style]) if options[:page_style]
        add_pair(post, :hdrimg, options[:header_image]) if options[:header_image]
        add_pair(post, :hdrbordercolor, options[:header_border_color]) if options[:header_border_color]
        add_pair(post, :hdrbackcolor, options[:hdr_back_color]) if options[:header_back_color]
        add_pair(post, :payflowcolor, options[:payflow_color]) if options[:payflow_color]
        add_pair(post, :email, options[:email]) if options[:email]
        post
      end

      def build_response(success, message, response, options = {})
        PaypalExpressReferenceNvResponse.new(success, message, response, options)
      end
    end

  end
end
