class Address < ActiveRecord::Base
  has_many :emails
  has_many :phone_numbers
  belongs_to :company
end
