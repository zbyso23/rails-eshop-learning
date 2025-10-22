class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  helper_method :current_cart, :current_user
  before_action :set_current_cart

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
    @current_user ||= User.first
  end
end
