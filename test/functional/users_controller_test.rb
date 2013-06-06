require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @carol = users(:carol)
    authenticate_with_http_digest 'alice', 'password1'
  end

  test "new" do
    get :new
    assert_response :success
    assert_template 'new'
  end

  test "create" do
    post :create, user: { name: 'david', notify_address: 'david@example.com', new_password: 'what', new_password_confirmation: 'what' }
    assert_redirected_to users_path
    assert flash[:notice] =~ /created/
    david = User.last
    assert_equal david.name, 'david'
    assert_equal david.notify_address, 'david@example.com'
    assert david.authenticate('what')
  end

  test "create should require a password" do
    post :create, user: { name: 'david' }
    assert_not_equal User.last.name, 'david'
  end

  test "edit" do
    get :edit, id: @alice.id
    assert_response :success
    assert_template 'edit'
    assert_equal assigns(:user), @alice
  end

  test "update" do
    put :update, id: @alice.id, user: { notify_address: 'alice-frd@example.com' }
    assert_redirected_to users_path
    assert flash[:notice] =~ /updated/
    assert @alice.reload.notify_address == 'alice-frd@example.com'
  end

  test "update should change password" do
    put :update, id: @alice.id, user: { change_password: 'on', current_password: 'password1', new_password: 'swordfish', new_password_confirmation: 'swordfish' }
    assert_redirected_to users_path
    assert flash[:notice] =~ /updated/
    assert @alice.reload.authenticate('swordfish')
  end

  test "destroy" do
    delete :destroy, id: @bob.id
    assert_redirected_to users_path
    assert flash[:notice] =~ /deleted/
    assert_nil User.find_by_id(@bob.id)
  end
end
