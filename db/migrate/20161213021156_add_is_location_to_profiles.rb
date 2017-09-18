class AddIsLocationToProfiles < ActiveRecord::Migration[5.0]
  def change
    add_column :profiles, :is_location, :boolean, default: false
  end
end
