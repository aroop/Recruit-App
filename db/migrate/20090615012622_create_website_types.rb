class CreateWebsiteTypes < ActiveRecord::Migration
  def self.up
    create_table :website_types do |t|
      t.string :name
    end
    WebsiteType.reset_column_information
    %w"Work Home Other".each do |type| 
      website_type = WebsiteType.new
      website_type.name = type
      website_type.save!
    end
  end

  def self.down
    drop_table :website_types
  end
end
