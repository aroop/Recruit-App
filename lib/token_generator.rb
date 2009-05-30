require 'guid'

module TokenGenerator
  def self.included(base)
    base.before_create :set_token
  end
  
  def set_token
    self.token = Guid.new.to_s
  end
end