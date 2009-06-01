# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def flash_notices
    [:notice, :error].collect {|type| content_tag('div', flash[type], :id => type) if flash[type] }
  end
  
  # Render a submit button and cancel link
  def submit_or_cancel(cancel_url = session[:return_to] ? session[:return_to] : url_for(:action => 'index'), label = 'Save Changes')
    content_tag(:div, submit_tag(label) + ' or ' +
      link_to('Cancel', cancel_url), :id => 'submit_or_cancel', :class => 'submit')
  end

  def discount_label(discount)
    (discount.percent? ? number_to_percentage(discount.amount * 100, :precision => 0) : number_to_currency(discount.amount)) + ' off'
  end
  
  def controller_is(*attrs) # <= check for one or multiple controllers
    attrs.collect{|attr| attr.to_s}.include?(controller.controller_name)
  end

  def action_is(*attrs) # <= check for  one or multiple actions
    attrs.map{|attr| attr.to_s}.include?(controller.action_name)
  end

  def controller_action_is(c,a) # <= check for controller and action
    controller_is(c) && action_is(a)
  end
  
  def month_array
    array_months = []
    Date::MONTHNAMES.each_with_index do |element, index|
      if (index > 0)
        array_months << ["#{index} - #{element}", index]
      end
    end
    array_months
  end
  
  def credit_card_types
    [["Visa", "visa"], ["MasterCard", "master"], ["Discover", "discover"], ["American Express", "american_express"]]
  end

end
