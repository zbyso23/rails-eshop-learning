class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_cart, :current_user, :user_signed_in?
  before_action :set_current_cart

  before_action :authenticate_user!
  before_action :set_current_cart

  # Pundit errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def current_cart
    @current_cart
  end

  def find_current_cart
    if current_user
      current_user.cart || current_user.create_cart
    # Jinak použijeme košík ze session, nebo vytvoříme nový
    elsif session[:cart_id]
      Cart.find_by(id: session[:cart_id]) || new_cart_for_session
    else
      new_cart_for_session
    end
  end

  def new_cart_for_session
    Cart.create.tap do |cart|
      session[:cart_id] = cart.id
    end
  end

  def set_current_cart
    @current_cart = find_current_cart
  end

  def current_user
    # Pro development - simulace přihlášeného usera
    # V produkci použij Devise nebo jinou autentizaci
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    unless user_signed_in?
      redirect_to login_path, alert: "Pro pokračování se musíte přihlásit"
    end
  end

  private

  def user_not_authorized
    flash[:alert] = "Nemáte oprávnění k této akci."
    redirect_to(request.referrer || root_path)
  end
end
