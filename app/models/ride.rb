class Ride < ActiveRecord::Base
  belongs_to :car_pool
  belongs_to :driver

  attr_accessible :date, :driver, :participants
  serialize :participants, Hash # driver_id => info hash, currently just { balance: ... }

  validates_presence_of :car_pool, :date

  def fare
    car_pool.ride_cost / participants.size
  end

  # updates in-memory balances for speculative rides
  # use charge! to charge the driver balances in the database frd
  def charge(ledger)
    return unless driver_id.present?
    participants.each_key do |driver_id|
      if driver_id == self.driver_id
        ledger[driver_id][:balance] += fare * (participants.size - 1)
        ledger[driver_id][:last_date_driven] = date
      else
        ledger[driver_id][:balance] -= fare
      end
    end
    nil
  end

  def assign_driver(ledger = nil)
    return if participants.size < 2
    self.driver_id = participants.map { |driver_id, info|
      last_date_driven = ledger[driver_id][:last_date_driven] if ledger
      last_date_driven ||= car_pool.last_date_driven(driver_id)
      last_date_driven ||= Date.today - 1.year
      info.merge(driver_id: driver_id, last_date_driven: last_date_driven)
    }.sort_by { |info| [ info[:balance], info[:last_date_driven] ] }.first[:driver_id]
  end

  def charged?
    self.charged
  end

  def charge!
    raise 'already charged' if charged?
    if driver
      raise 'driver not participating' unless participants.has_key? driver.id
      driver.credit! fare * (participants.size - 1)
      participants.each_key do |driver_id|
        Driver.find(driver_id).debit! fare unless driver_id == driver.id
      end
    else
      raise 'participants present, but no driver' unless participants.empty?
    end
    self.charged = true
    save!
  end

  def refund!
    raise 'not saved' if new_record?
    raise 'not charged' unless charged?
    raise 'too old to refund' unless last?
    if driver
      driver.debit! fare * (participants.size - 1)
      participants.each_key do |driver_id|
        Driver.find(driver_id).credit! fare unless driver_id == driver.id
      end
    end
    self.charged = false
    save!
  end

  # TODO fix deleting users from carpools.  this is so broken
  def display_driver
    { name: (driver.user.name rescue driver_id), balance: participants[driver_id][:balance].round(1) }
  end

  def display_passengers
    participants.keys.reject { |driver_id| driver_id == self.driver_id }.map do |driver_id|
      { name: (Driver.find(driver_id).user.name rescue driver_id), balance: participants[driver_id][:balance].round(1) }
    end
  end

  def update_participants(new_participants)
    new_drivers = new_participants.map do |part|
      car_pool.resolve_driver(part)
    end

    self.participants = {}
    new_drivers.each do |driver|
      self.participants[driver.id] = { balance: driver.balance }
    end
  end

  def last?
    self.id == car_pool.rides.order("date desc").limit(1).pluck(:id).first
  end
end
