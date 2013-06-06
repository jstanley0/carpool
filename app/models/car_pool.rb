class CarPool < ActiveRecord::Base
  RECENT_RIDES = 5
  UPCOMING_RIDES = 5

  belongs_to :schedule
  accepts_nested_attributes_for :schedule
  has_many :drivers, :dependent => :destroy
  has_many :rides, :dependent => :destroy
  has_many :users, :through => :drivers

  attr_accessible :name, :start_place, :start_time, :return_place, :return_time, :schedule_attributes

  validates_presence_of :name, :schedule

  def sync_memberships(user_ids)
    user_ids = user_ids.map(&:to_i)
    already_in = users.pluck(:id)
    to_add = user_ids - already_in
    to_remove = already_in - user_ids
    to_add.each { |user_id| enroll_user(user_id) }
    to_remove.each { |user_id| remove_user(user_id) }
    drivers.reload
  end

  def enroll_user(user_or_id)
    user_id = user_or_id.is_a?(User) ? user_or_id.id : user_or_id
    return if drivers.where(:user_id => user_id).exists?
    driver = drivers.build
    driver.user_id = user_id
    driver.schedule = Schedule.new
    driver.save!
    driver
  end

  def driver_id_for(user)
    drivers.where(:user_id => user.id).limit(1).pluck(:id).first
  end

  def driver_for(user)
    drivers.where(:user_id => user.id).limit(1).first
  end

  def find_driver_by_name(name)
    drivers.find_by_user_id!(User.find_by_name!(name))
  end

  def resolve_driver(name_or_id)
    if name_or_id.is_a? Driver
      name_or_id
    elsif name_or_id =~ /\d+/
      Driver.find(name_or_id.to_i)
    elsif name_or_id.is_a?(Fixnum)
      Driver.find(name_or_id)
    else
      find_driver_by_name(name_or_id)
    end
  end

  # participants can be Drivers, driver ids, or user names
  def build_ride(date, participants, ledger = nil)
    ride = rides.build date: date
    participants.each do |participant|
      driver = resolve_driver(participant)
      balance = if ledger && ledger[driver.id]
                  ledger[driver.id][:balance]
                else
                  driver.balance
                end
      ride.participants[driver.id] = { balance: balance }
    end
    ride
  end

  def build_ride!(date, participants = nil, driver = nil)
    ride = build_ride date, participants || drivers_for_date(date)
    if driver
      ride.driver = resolve_driver(driver)
    else
      ride.assign_driver
    end
    ride.charge!
    ride
  end

  def remove_user(user_id)
    drivers.where(:user_id => user_id).destroy_all
  end

  def recent_rides(count = RECENT_RIDES)
    rides.order("date desc").limit(count).reverse
  end

  def match_schedule(date, sched = nil)
    sched ||= self.schedule
    sched.match(date)
  end

  def drivers_for_date(date)
    drivers.all.select { |driver| match_schedule(date, driver.schedule) }
  end

  def last_date_driven(driver_id)
    rides.where(driver_id: driver_id).maximum(:date)
  end

  def to_ride?(date)
    match_schedule(date) && (date > rides.maximum(:date))
  end

  def future_dates(count, date = nil)
    dates = []
    date = [date, rides.maximum(:date).try(:+, 1.day)].compact.max
    lookahead = 30
    while dates.size < count && lookahead > 0
      dates << date if match_schedule(date)
      date += 1.day
      lookahead -= 1
    end
    dates
  end

  def build_ledger
    ledger = {}
    drivers.each do |driver|
      ledger[driver.id] = {balance: driver.balance, last_date_driven: last_date_driven(driver)}
    end
    ledger
  end

  # upcoming rides, for scheduling
  def future_rides(date = nil, count = UPCOMING_RIDES)
    dates = future_dates(count, date)
    ledger = build_ledger
    rides = dates.map do |date|
      ride = build_ride(date, drivers_for_date(date), ledger)
      ride.assign_driver(ledger)
      ride.charge(ledger)
      ride
    end
  end

  def find_or_build_ride_for_date(date)
    ride = rides.find_by_date(date)
    unless ride
      ride = build_ride(date, drivers_for_date(date))
      ride.assign_driver
    end
    ride
  end

end
