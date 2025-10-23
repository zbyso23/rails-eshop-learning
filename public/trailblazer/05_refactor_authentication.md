# V. Trailblazer Refactoring - Přihlašovací stránka + Authentication

## 1. Vytvoř SessionsController
`app/controllers/sessions_controller.rb`
```ruby
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  skip_before_action :set_current_cart, only: [:new, :create]
  
  def new
    # Formulář pro přihlášení
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
end
```

## 2. Routes
`config/routes.rb`

```ruby
# Přihlášení
get 'login', to: 'sessions#new'
post 'login', to: 'sessions#create'
delete 'logout', to: 'sessions#destroy'

# Pro development - rychlé přepínání
if Rails.env.development?
  post 'switch_user/:user_id', to: 'sessions#switch_user', as: :switch_user
end
```

## 3. View - Přihlašovací formulář
`app/views/sessions/new.html.erb`

```html
<div style="max-width: 400px; margin: 50px auto; padding: 20px; border: 1px solid #ccc; border-radius: 8px;">
  <h1>Přihlášení</h1>

  <% if flash[:alert] %>
    <div style="color: red; margin-bottom: 20px;">
      <%= flash[:alert] %>
    </div>
  <% end %>

  <%= form_with url: login_path, method: :post do |form| %>
    <div style="margin-bottom: 15px;">
      <%= form.label :email, "Email:" %>
      <%= form.email_field :email, required: true, autofocus: true, style: "width: 100%; padding: 8px;" %>
    </div>

    <div style="margin-bottom: 20px;">
      <%= form.submit "Přihlásit se", style: "width: 100%; padding: 10px; background: #007bff; color: white; border: none; border-radius: 4px; cursor: pointer;" %>
    </div>
  <% end %>

  <hr style="margin: 30px 0;">

  <h3>Testovací účty:</h3>
  <ul style="list-style: none; padding: 0;">
    <% User.all.each do |user| %>
      <li style="margin-bottom: 10px;">
        <%= form_with url: login_path, method: :post, style: "display: inline;" do |f| %>
          <%= f.hidden_field :email, value: user.email %>
          <%= f.submit "#{user.email} (#{user.role})", style: "padding: 8px 15px; cursor: pointer;" %>
        <% end %>
      </li>
    <% end %>
  </ul>
</div>
```

## 4. Update ApplicationController - vyžaduj přihlášení
`app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  allow_browser versions: :modern
  helper_method :current_cart, :current_user, :user_signed_in?
  
  # Vyžaduj přihlášení všude kromě přihlašovací stránky
  before_action :authenticate_user!
  before_action :set_current_cart
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  
  stale_when_importmap_changes

  protected

  def current_cart
    @current_cart
  end

  def find_current_cart
    if current_user
      current_user.cart || current_user.create_cart
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
```

## 5. SessionsController - přeskoč autentizaci
`app/controllers/sessions_controller.rb` (update)

```ruby
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  skip_before_action :set_current_cart, only: [:new, :create]
  
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
  
  # Pro development - rychlé přepínání uživatelů
  def switch_user
    if Rails.env.development?
      user = User.find(params[:user_id])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Přepnuto na: #{user.email} (#{user.role})"
    else
      redirect_to root_path, alert: "Tato funkce je dostupná pouze ve vývojovém prostředí"
    end
  end
end
```

## 6. Navigace - přidej odhlášení
`app/views/layouts/application.html.erb`

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Eshop</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <!-- Navigace -->
    <nav style="background: #333; color: white; padding: 15px;">
      <div style="max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center;">
        <div>
          <%= link_to "E-shop", root_path, style: "color: white; text-decoration: none; font-size: 20px; font-weight: bold;" %>
        </div>
        
        <% if user_signed_in? %>
          <div style="display: flex; gap: 20px; align-items: center;">
            <span><%= current_user.email %> (<%= current_user.role %>)</span>
            <%= link_to "Produkty", products_path, style: "color: white;" %>
            <%= link_to "Objednávky", orders_path, style: "color: white;" %>
            <%= link_to "Košík", cart_path(current_cart), style: "color: white;" %>
            <%= button_to "Odhlásit", logout_path, method: :delete, style: "background: #dc3545; color: white; border: none; padding: 8px 15px; border-radius: 4px; cursor: pointer;" %>
          </div>
        <% end %>
      </div>
    </nav>

    <!-- Development user switcher -->
    <% if Rails.env.development? && user_signed_in? %>
      <div style="background: #ffc107; padding: 10px; text-align: center;">
        <strong>DEV MODE:</strong> Přepnout na:
        <% User.all.each do |u| %>
          <% unless u.id == current_user.id %>
            <%= button_to u.email, switch_user_path(u), method: :post, style: "display: inline; margin: 0 5px; padding: 5px 10px; font-size: 12px;" %>
          <% end %>
        <% end %>
      </div>
    <% end %>

    <!-- Flash messages -->
    <% if notice %>
      <div style="background: #d4edda; color: #155724; padding: 15px; margin: 20px; border-radius: 4px;">
        <%= notice %>
      </div>
    <% end %>
    
    <% if alert %>
      <div style="background: #f8d7da; color: #721c24; padding: 15px; margin: 20px; border-radius: 4px;">
        <%= alert %>
      </div>
    <% end %>

    <!-- Main content -->
    <div style="max-width: 1200px; margin: 0 auto; padding: 20px;">
      <%= yield %>
    </div>
  </body>
</html>
```

## 7. Update seeds - přidej hesla (optional)
Pokud bys chtěl později použít Devise nebo bcrypt:

```ruby
# db/seeds.rb
admin = User.create!(
  email: 'admin@admin.com', 
  role: 'admin'
  # password: 'password123' - až přidáš has_secure_password
)
```

## 8. Test

```bash
# Restart Rails
rails restart

# Otevři prohlížeč
open http://localhost:3000
```

Mělo by se stát:

1. Přesměrování na `/login`
2. Výběr uživatele z testovacích účtů
3. Po přihlášení vidíš navigaci s odhlášením
4. V dev módu vidíš user switcher

✅ Přihlašovací stránka
✅ Ochrana všech stránek
✅ Odhlášení
✅ Testovací účty (klikací)
✅ Dev mode - rychlé přepínání uživatelů