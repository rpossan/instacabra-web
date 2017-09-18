class AddTotalMediaToProfiles < ActiveRecord::Migration[5.0]
  def change
    add_column :profiles, :total_media, :integer
  end
end
