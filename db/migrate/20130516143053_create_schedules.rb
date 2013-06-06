class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.boolean :mon, :default => true
      t.boolean :tue, :default => true
      t.boolean :wed, :default => true
      t.boolean :thu, :default => true
      t.boolean :fri, :default => true
      t.boolean :sat, :default => false
      t.boolean :sun, :default => false
      t.text :exceptions
    end
  end
end
