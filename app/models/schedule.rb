class Schedule < ActiveRecord::Base
  attr_accessible :fri, :mon, :sat, :sun, :thu, :tue, :wed, :in_list, :out_list
  serialize :exceptions, Hash  # date => boolean

  def in_list
    ret = ''
    exceptions.each do |date, val|
      ret << "#{date.to_s}\n" if val
    end
    ret
  end

  def in_list=(val)
    dates = val.split.map { |d| Date.parse(d) }
    exceptions.delete_if { |date, val| val }
    dates.each do |date|
      exceptions[date] = true
    end
  end

  def out_list
    ret = ''
    exceptions.each do |date, val|
      ret << "#{date.to_s}\n" unless val
    end
    ret
  end

  def out_list=(val)
    dates = val.split.map { |d| Date.parse(d) }
    exceptions.delete_if { |date, val| !val }
    dates.each do |date|
      exceptions[date] = false
    end
  end

  def match_day_of_week(date)
    wday_sym = date.strftime('%a').downcase.to_sym
    !!(self.send(wday_sym))
  end

  def match(date)
    return exceptions[date] if exceptions.has_key?(date)
    match_day_of_week(date)
  end

  def confirm!(date)
    exceptions[date] = true
    save!
  end

  def in!(date)
    exceptions.delete(date)
    exceptions[date] = true unless match_day_of_week(date)
    save!
  end

  def out!(date)
    exceptions.delete(date)
    exceptions[date] = false if match_day_of_week(date)
    save!
  end

  def cleanup!(cutoff_date)
    exceptions.delete_if { |k, v| k < cutoff_date }
    save!
  end
end
