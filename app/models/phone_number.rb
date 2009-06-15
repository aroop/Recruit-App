class PhoneNumber < ActiveRecord::Base
  has_one :phone_number_type
  belongs_to :address
end
