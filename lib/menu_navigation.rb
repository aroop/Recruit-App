module MenuNavigation
  
  def menu_navigation
    @menu_navigation = []
    @menu_navigation << MenuItem.new("Dashboard", dashboard_path)
    @menu_navigation << contacts_menu
    @menu_navigation << companies_menu
    @menu_navigation << candidates_menu
    @menu_navigation << jobs_menu
    @menu_navigation << MenuItem.new("Messages", messages_path)
    @menu_navigation << MenuItem.new("Analytics", "")
    @menu_navigation << MenuItem.new("Accounts", "")
  end
  
  def contacts_menu
    contact_menu = MenuItem.new("Contacts", contacts_path)
    contact_menu.children << MenuItem.new("Add new", new_contact_path, "sm1")
    contact_menu.children << MenuItem.new("List", contacts_path, "sm2")
    contact_menu
  end
  
  def companies_menu
    companies_menu = MenuItem.new("Companies", companies_path)
    companies_menu.children << MenuItem.new("Add new", new_company_path, "sm1")
    companies_menu.children << MenuItem.new("List", companies_path, "sm2")
    companies_menu
  end
  
  def candidates_menu
    candidates_menu = MenuItem.new("Candidates", candidates_path)
    candidates_menu.children << MenuItem.new("Add new", new_candidate_path, "sm1")
    candidates_menu.children << MenuItem.new("List", candidates_path, "sm2")    
    candidates_menu
  end
  
  def jobs_menu
    jobs_menu = MenuItem.new("Jobs", jobs_path)
    jobs_menu.children << MenuItem.new("Add new", new_job_path, "sm1")
    jobs_menu.children << MenuItem.new("List", jobs_path, "sm2")
    jobs_menu
  end
  
end