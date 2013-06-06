require 'test_helper'

class CarPoolsControllerTest < ActionController::TestCase

  test "should require authorization" do
    get :index
    assert_response :unauthorized
  end

  context "authorized" do
    setup do
      @test_carpool = car_pools(:test_carpool)
      @lame_carpool = car_pools(:lame_carpool)
      @alice = @test_carpool.driver_for(users(:alice))
      @bob = @test_carpool.driver_for(users(:bob))
      @carol = @test_carpool.driver_for(users(:carol))
      authenticate_with_http_digest 'alice', 'password1'
    end

    test "index" do
      get :index
      assert_response :success
      assert_template 'index'
      assert_equal assigns(:car_pools).map(&:id).sort, [@test_carpool.id, @lame_carpool.id].sort
    end

    test "record_ride" do
      get :record_ride, id: @test_carpool.id, date: '2013-06-03'
      assert_response :success
      assert_template 'record_ride'
      assert_equal assigns(:car_pool), @test_carpool
      assert_equal assigns(:date), Date.parse('2013-06-03')
      assert_not_nil assigns(:ride)
    end

    test "create_ride" do
      post :create_ride, id: @test_carpool.id, ride: { participants: [@alice.id, @bob.id, @carol.id], driver_id: @alice.id, date: Date.parse('2013-06-04') }
      assert_redirected_to root_path
      ride = @test_carpool.rides.first
      assert_not_nil ride
      assert_equal ride.driver_id, @alice.id
      assert_equal ride.participants, { @alice.id => {balance: 0}, @bob.id => {balance: 0}, @carol.id => {balance: 0} }
      assert ride.charged?
      assert_equal @alice.reload.balance, 8
      assert_equal @bob.reload.balance, -4
      assert_equal @carol.reload.balance, -4
    end

    test "create_ride should not rewrite history" do
      @test_carpool.build_ride! Date.parse('2013-06-04'), [@alice, @bob, @carol]
      post :create_ride, id: @test_carpool.id, ride: { participants: [@alice.id, @bob.id, @carol.id], driver_id: @bob.id, date: Date.parse('2013-06-04') }
      assert_equal @test_carpool.rides.count, 1
      assert flash[:error] =~ /can't rewrite history/
      assert_redirected_to root_path
    end

    test "update_ride" do
      @alice.balance = -6; @alice.save!
      @bob.balance = 6; @bob.save!
      ride = @test_carpool.build_ride! Date.parse('2013-06-04'), [@alice, @bob]
      put :update_ride, id: @test_carpool.id, ride_id: ride.id, ride: { participants: [@alice.id, @bob.id, @carol.id], driver_id: @alice.id, date: Date.parse('2013-06-04') }
      assert_redirected_to root_path
      ride.reload
      assert ride.charged?
      assert_equal ride.participants, { @alice.id => {balance: -6}, @bob.id => {balance: 6}, @carol.id => {balance: 0} }
      assert_equal @alice.reload.balance, 2
      assert_equal @bob.reload.balance, 2
      assert_equal @carol.reload.balance, -4
    end

    test "update_ride should change dates" do
      ride = @test_carpool.build_ride! Date.parse('2013-06-04'), [@alice, @bob, @carol]
      put :update_ride, id: @test_carpool.id, ride_id: ride.id, ride: { participants: [@alice.id, @bob.id, @carol.id], driver_id: @bob.id, date: Date.parse('2013-06-01') }
      assert_redirected_to root_path
      assert_equal ride.reload.date, Date.parse('2013-06-01')
    end

    test "update_ride should not rewrite history" do
      @test_carpool.build_ride! Date.parse('2013-06-03'), [@alice, @bob, @carol]
      ride = @test_carpool.build_ride! Date.parse('2013-06-04'), [@alice, @bob, @carol]
      put :update_ride, id: @test_carpool.id, ride_id: ride.id, ride: { participants: [@alice.id, @bob.id, @carol.id], driver_id: @bob.id, date: Date.parse('2013-06-01') }
      assert_redirected_to root_path
      assert_equal ride.reload.date, Date.parse('2013-06-04')
      assert flash[:error] =~ /can't rewrite history/
    end

    test "new" do
      get :new
      assert_response :success
      assert_template 'new'
      assert_not_nil assigns(:car_pool)
      assert_not_nil assigns(:car_pool).schedule
    end

    test "edit" do
      get :edit, id: @test_carpool.id
      assert_response :success
      assert_template 'edit'
      assert_equal assigns(:car_pool), @test_carpool
    end

    test "create" do
      post :create, car_pool: { name: 'new carpool!', start_place: 'start here', start_time: '09:30', return_place: 'there', return_time: '14:45',
        schedule_attributes: { wed: false, in_list: '2013-07-01', out_list: '2013-07-02' },
        member_ids: [users(:alice).id] }
      pool = CarPool.last
      assert_equal pool.name, 'new carpool!'
      assert_equal pool.start_place, 'start here'
      assert_equal pool.start_time, '09:30'
      assert_equal pool.return_place, 'there'
      assert_equal pool.return_time, '14:45'
      assert_equal pool.schedule.wed, false
      assert_equal pool.schedule.exceptions, { Date.parse('2013-07-01') => true, Date.parse('2013-07-02') => false }
      assert flash[:notice] =~ /successfully created/
      assert_redirected_to car_pools_path
    end

    test "update" do
      @alice = users(:alice)
      @bob = users(:bob)
      put :update, id: @test_carpool.id, car_pool: { name: 'updated', schedule_attributes: { sat: true }, member_ids: [@alice.id, @bob.id] }
      @test_carpool.reload
      assert_equal @test_carpool.name, 'updated'
      assert_equal @test_carpool.schedule.sat, true
      assert flash[:notice] =~ /successfully updated/
      assert_equal @test_carpool.users.map(&:id).sort, [@alice, @bob].map(&:id).sort
      assert_redirected_to car_pools_path
    end

    test "update should not touch memberships if member_ids not present" do
      put :update, id: @test_carpool.id, car_pool: { name: 'whaaat' }
      @test_carpool.reload
      assert_equal @test_carpool.name, 'whaaat'
      assert_equal @test_carpool.users.count, 3
    end

    test "update should ignore the placeholder parameter" do
      @alice = users(:alice)
      put :update, id: @test_carpool.id, car_pool: { member_ids: [@alice.id, 'placeholder'] }
      @test_carpool.reload
      assert_equal @test_carpool.users.map(&:id), [@alice.id]
    end

    test "destroy" do
      delete :destroy, id: @lame_carpool.id
      assert_nil CarPool.find_by_id(@lame_carpool.id)
      assert flash[:notice] =~ /successfully deleted/
      assert_redirected_to car_pools_path
    end
  end
end
