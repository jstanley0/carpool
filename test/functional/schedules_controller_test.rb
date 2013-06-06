require 'test_helper'

=begin
  bob_schedule: {
    sun: false,
    mon: false,
    tue: true,
    wed: false,
    thu: true,
    fri: false,
    sat: false,
    exceptions: {
      2013-06-05: true,
      2013-06-06: false
    }
  }
=end

class SchedulesControllerTest < ActionController::TestCase
  setup do
    @schedule = schedules(:bob_schedule)
    authenticate_with_http_digest 'bob', 'hunter2'
  end

  test "in" do
    date = Date.parse('2013-06-06')
    assert !@schedule.match(date)
    get :in, id: @schedule.id, date: date
    assert @schedule.reload.match(date)
    assert_redirected_to root_path
  end

  test "out" do
    date = Date.parse('2013-06-18')
    assert @schedule.match(date)
    get :out, id: @schedule.id, date: date
    assert !@schedule.reload.match(date)
    assert_redirected_to root_path
  end

  test "edit" do
    get :edit, id: @schedule.id
    assert_response :success
    assert_template 'edit'
    assert_equal assigns(:schedule), @schedule
  end

  test "update" do
    put :update, id: @schedule.id, schedule: { wed: true, in_list: '2013-07-01 2013-07-02', out_list: "2013-07-03\n2013-07-04" }
    @schedule.reload
    assert_equal @schedule.wed, true
    assert @schedule.match(Date.parse('2013-07-01'))
    assert @schedule.match(Date.parse('2013-07-02'))
    assert !@schedule.match(Date.parse('2013-07-03'))
    assert !@schedule.match(Date.parse('2013-07-04'))
    assert_redirected_to root_path
    assert flash[:notice] =~ /updated/
  end
end
