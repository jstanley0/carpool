class HomeController < ApplicationController
  def index
    @carpools = @current_user.car_pools.all
  end
end
