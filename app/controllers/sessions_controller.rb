class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :new, :create ]
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ]
  skip_before_action :set_current_cart, only: [ :new, :create ]


  def new
    # Pokud už je přihlášen, přesměruj na hlavní stránku
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email])

    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Vítejte, #{user.email}!"
    else
      flash.now[:alert] = "Neplatný email"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Byli jste odhlášeni"
  end
  def switch_user
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Přepnuto na: #{user.email} (#{user.role})"
  end
end
