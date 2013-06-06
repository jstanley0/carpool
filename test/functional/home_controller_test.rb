require 'test_helper'

class HomeControllerTest < ActionController::TestCase

  test "should require authorization" do
    get :index
    assert_response :unauthorized
  end

  context "with bad password" do
    setup do
      authenticate_with_http_digest 'bob', 'what'
    end

    test "should reject invalid password" do
      get :index
      assert_response :unauthorized
    end
  end

  context "index" do
    setup do
      @test_carpool = car_pools(:test_carpool)
      @lame_carpool = car_pools(:lame_carpool)
    end

    test "should include all a user's carpools" do
      authenticate_with_http_digest 'bob', 'hunter2'
      get :index
      assert_response :success
      assert_equal assigns(:carpools).map(&:id).sort, [@test_carpool.id, @lame_carpool.id].sort
    end

    test "should include only a user's carpools" do
      authenticate_with_http_digest 'alice', 'password1'
      get :index
      assert_response :success
      assert_equal assigns(:carpools).map(&:id), [@test_carpool.id]
    end
  end
end
