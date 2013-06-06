class CreateRides < ActiveRecord::Migration
  def change
    create_table :rides do |t|
      t.references :car_pool
      t.date :date
      t.references :driver
      t.boolean :charged
      t.text :participants

      t.timestamps
    end
    add_index :rides, :car_pool_id
    add_index :rides, :driver_id
    add_index :rides, :date
  end
end
