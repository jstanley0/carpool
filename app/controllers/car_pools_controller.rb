class CarPoolsController < ApplicationController
  # GET /car_pools
  # GET /car_pools.json
  def index
    @car_pools = CarPool.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @car_pools }
    end
  end

  # GET /car_pools/1/record_ride/:date
  def record_ride
    @car_pool = CarPool.find(params[:id])
    @date = Date.parse(params[:date])
    @ride = @car_pool.find_or_build_ride_for_date(@date)
    respond_to do |format|
      format.html # record_ride.html.erb
    end
  end

  # POST /car_pools/1/rides
  def create_ride
    raise "missing ride" unless params[:ride].present?
    raise "missing date" unless params[:ride][:date].present?
    @car_pool = CarPool.find(params[:id])
    if @car_pool.rides.where(["rides.date >= ?", params[:ride][:date]]).exists?
      respond_to do |format|
        format.html { redirect_to root_path, flash: {error: "Failed to create ride: can't rewrite history"} }
        format.json { render json: {message: "can't rewrite history"}, status: :bad_request }
      end
      return
    end
    participants = Array(params[:ride][:participants])
    @ride = @car_pool.build_ride(Date.parse(params[:ride][:date]), participants)
    @ride.driver = @car_pool.resolve_driver(params[:ride][:driver_id]) if params[:ride][:driver_id].to_i > 0
    @ride.charge!
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: @ride }
    end
  end

  # PUT /car_pools/1/rides/1
  def update_ride
    raise "missing ride" unless params[:ride].present?
    raise "missing date" unless params[:ride][:date].present?
    @car_pool = CarPool.find(params[:id])
    @ride = @car_pool.rides.find(params[:ride_id])
    if @car_pool.rides.where(["rides.id <> ? AND rides.date >= ?", @ride.id, params[:ride][:date]]).exists?
      respond_to do |format|
        format.html { redirect_to root_path, flash: {error: "Failed to update ride: can't rewrite history"} }
        format.json { render json: {message: "can't rewrite history"}, status: :bad_request }
      end
      return
    end
    @ride.refund! if @ride.charged?
    @ride.date = Date.parse(params[:ride][:date])
    if params[:ride][:driver_id].present?
      if params[:ride][:driver_id].to_s == '0'
        @ride.driver = nil
      else
        @ride.driver = @car_pool.resolve_driver(params[:ride][:driver_id])
      end
    end
    @ride.update_participants(Array(params[:ride][:participants]))
    @ride.charge!
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: @ride }
    end
  end

  # GET /car_pools/new
  # GET /car_pools/new.json
  def new
    @car_pool = CarPool.new
    @car_pool.schedule = Schedule.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @car_pool }
    end
  end

  # GET /car_pools/1/edit
  def edit
    @car_pool = CarPool.find(params[:id])
  end

  # POST /car_pools
  # POST /car_pools.json
  def create
    member_ids = get_member_ids(params[:car_pool])
    @car_pool = CarPool.new(params[:car_pool])
    @car_pool.schedule ||= Schedule.new
    respond_to do |format|
      if @car_pool.save
        @car_pool.sync_memberships(member_ids) if member_ids
        format.html { redirect_to car_pools_path, notice: 'Car pool was successfully created.' }
        format.json { render json: @car_pool, status: :created, location: @car_pool }
      else
        format.html { render action: "new" }
        format.json { render json: @car_pool.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /car_pools/1
  # PUT /car_pools/1.json
  def update
    @car_pool = CarPool.find(params[:id])
    member_ids = get_member_ids(params[:car_pool])
    respond_to do |format|
      if @car_pool.update_attributes(params[:car_pool]) && @car_pool.schedule.save
        @car_pool.sync_memberships(member_ids) if member_ids
        format.html { redirect_to car_pools_path, notice: 'Car pool was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @car_pool.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /car_pools/1
  # DELETE /car_pools/1.json
  def destroy
    @car_pool = CarPool.find(params[:id])
    @car_pool.destroy

    respond_to do |format|
      format.html { redirect_to car_pools_path, notice: 'Car pool was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # the web form includes a placeholder, so we can distingiush
  # not providing member_ids[] vs. providing an empty one
  def get_member_ids(car_pool_params)
    member_ids = car_pool_params.delete(:member_ids)
    return nil if member_ids.nil? # parameter not provided
    member_ids.reject { |id| id == 'placeholder' }
  end
end
