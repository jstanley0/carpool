class CreateDrivers < ActiveRecord::Migration
  def change
    create_table :drivers do |t|
      t.references :user
      t.references :car_pool
      t.float :balance, default: 0
      t.references :schedule

      t.timestamps
    end
    add_index :drivers, :user_id
    add_index :drivers, :car_pool_id
    add_index :drivers, :schedule_id
  end
end
