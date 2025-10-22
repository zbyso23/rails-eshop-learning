class ApplicationController < ActionController::Base
  helper_method :current_cart
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def find_or_create_cart
    cart_id_in_session = session[:cart_id]

    if current_user && current_user.cart
      # Uživatele s košíkem, vezmeme ten jeho
      current_user.cart
    elsif current_user && cart_id_in_session
      # Uživatel se právě přihlásil a má košík v session
      # Přiřadíme košík z session k uživateli
      cart = Cart.find(cart_id_in_session)
      cart.update(user: current_user)
      session.delete(:cart_id)
      cart
    elsif cart_id_in_session
      # Anonymní uživatel s košíkem v session
      begin
        Cart.find(cart_id_in_session)
      rescue ActiveRecord::RecordNotFound
        # Košík z session zmizel, vytvoříme nový
        Cart.create.tap { |cart| session[:cart_id] = cart.id }
      end
    else
      # Žádný košík, vytvoříme nový a uložíme do session
      Cart.create.tap { |cart| session[:cart_id] = cart.id }
    end
  end
end
