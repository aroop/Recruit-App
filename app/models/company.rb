class Company < ActiveRecord::Base
  has_one :address
  belongs_to :account
  
  validates_presence_of :name
  
  cattr_reader :per_page
  @@per_page = 2
  
end
