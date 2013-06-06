require 'test_helper'

class ScheduleTest < ActiveSupport::TestCase
  setup do
    @schedule = schedules(:bob_schedule)
  end
  # this schedule matches tue, thu
  # and has an override-in on wed 2013-06-05
  # and an exclusion on thu 2013-06-06

  context "in" do
    test "remove negative exception" do
      date = Date.new(2013, 6, 6)
      assert_false @schedule.match(date)
      assert_equal @schedule.exceptions[date], false
      @schedule.in! date
      assert @schedule.match(date)
      assert_nil @schedule.exceptions[date]
    end

    test "add positive exception" do
      date = Date.new(2013, 6, 3)
      assert_false @schedule.match(date)
      assert_nil @schedule.exceptions[date]
      @schedule.in! date
      assert @schedule.match(date)
      assert_equal @schedule.exceptions[date], true
    end
  end

  context "out" do
    test "remove positive exception" do
      date = Date.new(2013, 6, 5)
      assert @schedule.match(date)
      assert_equal @schedule.exceptions[date], true
      @schedule.out! date
      assert_false @schedule.match(date)
      assert_nil @schedule.exceptions[date]
    end

    test "add negative exception" do
      date = Date.new(2013, 6, 4)
      assert @schedule.match(date)
      assert_nil @schedule.exceptions[date]
      @schedule.out! date
      assert_false @schedule.match(date)
      assert_equal @schedule.exceptions[date], false
    end
  end

end