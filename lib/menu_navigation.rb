module MenuNavigation
  
  def menu_navigation
    @menu_navigation = []
    @menu_navigation << MenuItem.new("Dashboard", dashboard_path)
    @menu_navigation << contacts_menu
    @menu_navigation << MenuItem.new("Candidates", "/")
    @menu_navigation << MenuItem.new("Companies", "")
    @menu_navigation << MenuItem.new("Jobs", "")
    @menu_navigation << MenuItem.new("Messages", "")
    @menu_navigation << MenuItem.new("Accounts", "")
  end
  
  def contacts_menu
    contact_menu = MenuItem.new("Contacts", contacts_path)
    contact_menu.children << MenuItem.new("Add new", new_contact_path, "sm1")
    contact_menu.children << MenuItem.new("List", contacts_path, "sm2")
    contact_menu
  end
  
end