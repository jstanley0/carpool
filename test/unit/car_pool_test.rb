require 'test_helper'

class CarPoolTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @carol = users(:carol)
  end

  context "sync_memberships" do
    setup do
      @carpool = CarPool.new name: 'test'
      @carpool.schedule = Schedule.new
      @carpool.save!
      @alice_driver = @carpool.enroll_user @alice
      @bob_driver = @carpool.enroll_user @bob
    end

    test "should add remove and preserve memberships" do
      @carpool.sync_memberships([@bob.id, @carol.id])
      @carpool.reload
      assert_equal @carpool.users.map(&:id).sort, [@bob.id, @carol.id].sort
      assert_equal @bob_driver.id, @carpool.driver_id_for(@bob)
    end

    test "should remove all memberships" do
      @carpool.sync_memberships([])
      assert_empty @carpool.drivers
    end
  end

  test "build_ride" do
    @carpool = car_pools(:test_carpool)
    drivers(:alice_driver).update_attribute(:balance, 4)
    ride = @carpool.build_ride Date.parse('2013-06-01'), %w(alice bob)
    assert_nil ride.driver_id
    assert_equal ride.date, Date.parse('2013-06-01')
    assert_equal ride.participants, {
        drivers(:alice_driver).id => { balance: 4 },
        drivers(:bob_driver).id => { balance: 0 }
    }
  end

  test "resolve_driver" do
    @carpool = car_pools(:test_carpool)
    @driver = drivers(:alice_driver)
    assert_equal @carpool.resolve_driver(@driver), @driver
    assert_equal @carpool.resolve_driver("#{@driver.id}"), @driver
    assert_equal @carpool.resolve_driver(@driver.id), @driver
    assert_equal @carpool.resolve_driver('alice'), @driver
  end

  context "dates" do
    setup do
      @carpool = car_pools(:test_carpool)
      @alice_driver = drivers(:alice_driver)
      @bob_driver = drivers(:bob_driver)
      @carol_driver = drivers(:carol_driver)
    end

    test "drivers_for_date" do
      assert_equal @carpool.drivers_for_date(Date.new(2013, 6, 2)).sort, [] # sun
      assert_equal @carpool.drivers_for_date(Date.new(2013, 6, 3)).map(&:id).sort, [@alice_driver.id, @carol_driver.id].sort # mon
      assert_equal @carpool.drivers_for_date(Date.new(2013, 6, 4)).map(&:id).sort, [@alice_driver.id, @bob_driver.id, @carol_driver.id].sort # tue
    end

    test "ledger" do
      @carpool.build_ride! Date.new(2013, 6, 3), %w(alice carol), 'alice'
      @carpool.build_ride! Date.new(2013, 6, 4), %w(alice bob carol), 'bob'
      @carpool.build_ride! Date.new(2013, 6, 5), %w(alice carol), 'carol'
      @carpool.build_ride! Date.new(2013, 6, 6), %w(alice bob carol), 'bob'
      @carpool.build_ride! Date.new(2013, 6, 7), %w(alice bob), 'alice'

      ledger = @carpool.build_ledger
      assert_equal ledger, {
        @alice_driver.id => { balance: -2 , last_date_driven: Date.new(2013, 6, 7) },
        @bob_driver.id => { balance: 10, last_date_driven: Date.new(2013, 6, 6) },
        @carol_driver.id => { balance: -8, last_date_driven: Date.new(2013, 6, 5) }
      }
    end
  end

  test "future_rides" do
    @carpool = car_pools(:test_carpool)
    future_rides = @carpool.future_rides(Date.new(2013, 12, 22))
    # the below skips weekends and holidays excluded by the Schedule
    assert_equal future_rides.map(&:date), [
        Date.new(2013, 12, 23),
        Date.new(2013, 12, 24),
        Date.new(2013, 12, 26),
        Date.new(2013, 12, 27),
        Date.new(2013, 12, 30)
    ]
  end
end
