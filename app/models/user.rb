class User < ActiveRecord::Base
  extend PasswordDigest
  has_password_digest

  has_many :drivers, :dependent => :destroy
  has_many :car_pools, :through => :drivers
  attr_accessible :name, :notify_address

  validates_presence_of :name
end
