class CreateProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :profiles do |t|
      t.string :username
      t.boolean :ripped, default: false
      t.integer :job_id

      t.timestamps
    end
  end
end
