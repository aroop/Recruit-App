module StaticHelper
  
  def price(plan)
    if (plan.amount <= 0)
      "Free forever"
    else
      "$ #{plan.amount.to_i} monthly"
    end
  end
  
  def employee_limit(plan)
    if (plan.user_limit.nil?)
      "Unlimited"
    else
      plan.user_limit
    end    
  end
  
  def storage(plan)
    if (plan.storage.nil?)
      "No files"
    else
      "#{plan.storage} GB"
    end    
  end
  
end
