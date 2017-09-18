class CreateJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs do |t|
      t.string :input
      t.integer :total_profiles, default: 0
      t.integer :total_media, default: 0
      t.integer :ripped_media, default: 0
      t.boolean :done, default: false

      t.timestamps
    end
  end
end
