class StaticController < ApplicationController
  
  skip_before_filter :login_required
  layout  "static"
  
  def index
    
  end
  
  def tour
    
  end
  
  def blog
    
  end
  
  def support
    
  end
  
  def contact
    
  end
  
end
