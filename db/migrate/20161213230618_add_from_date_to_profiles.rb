class AddFromDateToProfiles < ActiveRecord::Migration[5.0]
  def change
    add_column :profiles, :from_date, :integer, default: 0
  end
end
