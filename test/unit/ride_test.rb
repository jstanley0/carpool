require 'test_helper'

class RideTest < ActiveSupport::TestCase
  setup do
    @carpool = car_pools(:test_carpool)
    @alice = drivers(:alice_driver)
    @bob = drivers(:bob_driver)
    @carol = drivers(:carol_driver)
  end

  context "speculative" do
    context "charge" do
      setup do
        @ledger = { @alice.id => { balance: -4, last_date_driven: Date.new(2013, 6, 3) },
                    @bob.id => { balance: -2, last_date_driven: Date.new(2013, 6, 4) },
                    @carol.id => { balance: 6, last_date_driven: Date.new(2013, 6, 5) } }
        @ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob, @carol], @ledger
      end

      test "with driver" do
        @ride.driver = @alice
        @ride.charge @ledger
        assert_equal @ledger[@alice.id][:balance], 4
        assert_equal @ledger[@bob.id][:balance], -6
        assert_equal @ledger[@carol.id][:balance], 2
      end

      test "without driver" do
        @ride.charge @ledger
        assert_equal @ledger[@alice.id][:balance], -4
        assert_equal @ledger[@bob.id][:balance], -2
        assert_equal @ledger[@carol.id][:balance], 6
      end

      test "reduced participation" do
        @ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob], @ledger
        @ride.driver = @alice
        @ride.charge @ledger
        assert_equal @ledger[@alice.id][:balance], 2
        assert_equal @ledger[@bob.id][:balance], -8
        assert_equal @ledger[@carol.id][:balance], 6
      end
    end

    context "assign_driver" do
      test "it picks the lowest balance" do
        @ledger = { @alice.id => { balance: -4, last_date_driven: Date.new(2013, 6, 3) },
                    @bob.id => { balance: -2, last_date_driven: Date.new(2013, 6, 4) },
                    @carol.id => { balance: 6, last_date_driven: Date.new(2013, 6, 5) } }
        @ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob, @carol], @ledger
        @ride.assign_driver(@ledger)
        assert_equal @ride.driver, @alice
      end

      test "it breaks ties by last date driven" do
        @ledger = { @alice.id => { balance: 8, last_date_driven: Date.new(2013, 6, 3) },
                    @bob.id => { balance: -4, last_date_driven: Date.new(2013, 6, 4) },
                    @carol.id => { balance: -4, last_date_driven: Date.new(2013, 6, 5) } }
        @ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob, @carol], @ledger
        @ride.assign_driver(@ledger)
        assert_equal @ride.driver, @bob
      end

      test "never having driven is like long ago" do
        @ledger = { @alice.id => { balance: 8, last_date_driven: Date.new(2013, 6, 3) },
                    @bob.id => { balance: -4, last_date_driven: Date.new(2013, 6, 4) },
                    @carol.id => { balance: -4, last_date_driven: nil } }
        @ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob, @carol], @ledger
        @ride.assign_driver(@ledger)
        assert_equal @ride.driver, @carol
      end
    end
  end

  context "frd" do
    setup do
      @alice.update_attribute(:balance, -4)
      @bob.update_attribute(:balance, -2)
      @carol.update_attribute(:balance, 6)
    end

    test "charge!" do
      ride = @carpool.build_ride Date.new(2013, 6, 6), [@alice, @bob]
      ride.driver = @alice
      ride.charge!
      assert ride.charged?
      assert_false ride.changed? # saved
      assert_equal @alice.reload.balance, 2
      assert_equal @bob.reload.balance, -8
      assert_equal @carol.reload.balance, 6
    end

    test "refund!" do
      ride = @carpool.build_ride Date.new(2013, 6, 11), [@alice, @bob, @carol]
      ride.driver = @alice
      ride.charge!
      assert_equal @alice.reload.balance, 4
      assert_equal @bob.reload.balance, -6
      assert_equal @carol.reload.balance, 2

      ride.refund!
      assert_false ride.charged?
      assert_equal @alice.reload.balance, -4
      assert_equal @bob.reload.balance, -2
      assert_equal @carol.reload.balance, 6
    end

    test "last?" do
      ride1 = @carpool.build_ride! Date.new(2013, 6, 11)
      ride2 = @carpool.build_ride! Date.new(2013, 6, 12)
      assert_false ride1.last?
      assert ride2.last?
    end

    context "assign_driver" do
      setup do
        @carpool.build_ride! Date.new(2013, 6, 11), %w(bob carol), 'bob'         # -> -4, 4, 0
        @carpool.build_ride! Date.new(2013, 6, 12), %w(alice bob carol), 'alice' # -> 4, 0, -4
      end

      test "it picks the one with lowest balance" do
        ride = @carpool.build_ride! Date.new(2013, 6, 13), %w(alice bob carol)
        assert_equal ride.driver, @carol
      end

      test "it breaks ties by whoever drove longest ago" do
        @alice.update_attribute(:balance, -4)
        @bob.update_attribute(:balance, -4)
        @carol.update_attribute(:balance, 8)
        ride = @carpool.build_ride! Date.new(2013, 6, 13), %w(alice bob carol)
        assert_equal ride.driver, @bob
      end

      test "never having driven counts as long ago" do
        @alice.update_attribute(:balance, -4)
        @bob.update_attribute(:balance, 8)
        @carol.update_attribute(:balance, -4)
        ride = @carpool.build_ride! Date.new(2013, 6, 13), %w(alice bob carol)
        assert_equal ride.driver, @carol
      end
    end
  end
end
