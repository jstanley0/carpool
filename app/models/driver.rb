class Driver < ActiveRecord::Base
  belongs_to :user
  belongs_to :car_pool
  belongs_to :schedule
  has_many :rides

  attr_accessible :user, :car_pool
  validates_presence_of :user, :car_pool, :schedule

  def debit!(amount)
    self.balance -= amount
    save!
  end

  def credit!(amount)
    self.balance += amount
    save!
  end
end
