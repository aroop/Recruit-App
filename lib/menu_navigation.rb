module MenuNavigation
  
  def menu_navigation
    @menu_navigation = []
    @menu_navigation << MenuItem.new("Dashboard", dashboard_path)
    @menu_navigation << contacts_menu
    @menu_navigation << MenuItem.new("Companies", companies_path)
    @menu_navigation << MenuItem.new("Candidates", candidates_path)
    @menu_navigation << MenuItem.new("Jobs", jobs_path)
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
  
end