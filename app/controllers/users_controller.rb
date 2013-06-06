class UsersController < ApplicationController
  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    password_params = params[:user].extract! :change_password, :current_password, :new_password, :new_password_confirmation
    @user = User.new(params[:user])
    @user.password = password_params[:new_password]
    @user.password_confirmation = password_params[:new_password_confirmation]

    respond_to do |format|
      if @user.save
        format.html { redirect_to users_url, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
    params[:user] ||= {}
    respond_to do |format|
      password_params = params[:user].extract! :change_password, :current_password, :new_password, :new_password_confirmation
      if password_params[:change_password]
        if !@user.authenticate(password_params[:current_password])
          @user.errors.add(:current_password, 'is incorrect')
          return render action: "edit"
        end
        @user.name = params[:user][:name] if params[:user][:name].present?
        @user.password = password_params[:new_password]
        @user.password_confirmation = password_params[:new_password_confirmation]
        unless @user.save
          return render action: "edit"
        end
      end

      if @user.update_attributes(params[:user])
        format.html { redirect_to users_url, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
