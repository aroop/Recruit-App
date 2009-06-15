class Email < ActiveRecord::Base
  has_one :email_type
  belongs_to :address
end
