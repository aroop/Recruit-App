require File.dirname(__FILE__) + '/../../spec_helper'

describe "/accounts/edit" do
  before(:each) do
    assigns[:account] = @account = accounts(:localhost)
  end
  
  it 'should have a form for editing the account' do
    render 'accounts/edit'
    response.should have_tag('form[action=?]', account_path) do |form|
      form.should have_tag('input[id=account_name][value=?]', @account.name)
    end
  end
  
  it "should display errors" do
    assigns[:account].errors.add(:name, "can't be blank")
    render 'accounts/edit'
    response.should have_tag('li', "Name can't be blank")
  end
end
