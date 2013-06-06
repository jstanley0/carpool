class SchedulesController < ApplicationController
  def in
    Schedule.find(params[:id]).in!(Date.parse(params[:date]))
    redirect_to root_path
  end

  def out
    Schedule.find(params[:id]).out!(Date.parse(params[:date]))
    redirect_to root_path
  end

  def confirm
    Schedule.find(params[:id]).confirm!(Date.parse(params[:date]))
    redirect_to root_path
  end

  def edit
    @schedule = Schedule.find(params[:id])
  end

  def update
    @schedule = Schedule.find(params[:id])
    respond_to do |format|
      if @schedule.update_attributes(params[:schedule])
        format.html { redirect_to root_path, notice: 'Schedule updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @car_pool.errors, status: :unprocessable_entity }
      end
    end
  end

end
