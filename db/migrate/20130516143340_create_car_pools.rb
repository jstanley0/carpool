class CreateCarPools < ActiveRecord::Migration
  def change
    create_table :car_pools do |t|
      t.string :name
      t.float :ride_cost, :default => 12
      t.references :schedule
      t.string :start_place
      t.string :start_time
      t.string :return_place
      t.string :return_time

      t.timestamps
    end
    add_index :car_pools, :schedule_id
  end
end
