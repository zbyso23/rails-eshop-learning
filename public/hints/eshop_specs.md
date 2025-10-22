# Eshop concept

**Funkcionalita webové aplikace (e-shop)**
```
Kategorie: Umožní organizaci produktů.
Vytváření, úprava a mazání kategorií.
Zobrazení seznamu kategorií.
Produkty: Základní stavební kámen obchodu.
Přidání, úprava a mazání produktů.
Produkty musí mít přiřazenou alespoň jednu kategorii.
Stránkování a filtrování produktů na frontendu.
Komentáře a hodnocení: Funkce pro interakci zákazníků.
Uživatelé mohou přidávat komentáře k produktům.
Uživatelé mohou hodnotit produkty (např. 1 až 5 hvězdiček).
Moderace komentářů a hodnocení (např. administrátorem).
Košík: Místo, kam si uživatelé ukládají zboží před nákupem.
Přidání produktu do košíku.
Úprava množství produktu v košíku.
Odstranění produktu z košíku.
Zobrazení obsahu košíku a celkové ceny.
Objednávky: Proces dokončení nákupu.
Vytvoření objednávky z obsahu košíku.
Správa stavů objednávky (např. přijatá, odeslaná, doručená).
Zobrazení historie objednávek pro uživatele.
Administrace objednávek (seznam, detaily, změna stavu).

API routy
Export objednávek:
Jednoduchá API routa pro export dat o objednávkách (např. ve formátu JSON nebo CSV).
Může být určena pro interní potřeby (např. účetnictví).
Vyžaduje ověření (autentizaci) přístupu.
Import produktů:
API routa pro import dat o produktech (např. ve formátu JSON).
Umožní hromadné nahrávání produktů.
Také vyžaduje ověření.
```

## Architektura a postupy

### První fáze (Rails):
Zaměření se na standardní MVC přístup, jak jej Rails prezentuje. Využití Active Record, vestavěných helperů a konvencí.

### Druhá fáze (Trailblazer):
Po zvládnutí základu se stejná funkčnost přepíše s použitím Trailblazeru, který oddělí business logiku od kontrolerů 
a modelů do samostatných operací. To pomůže pochopit výhody oddělené architektury. 


# Setup

## Postgres Install
```bash
apt upadate
apt install postgresql postgresql-contrib
```

## Postgres setup password
```bash
sudo -i -u postgres psql
\password postgres
```

## Postgres setup localhost connection
```bash
vim /etc/postgresql/<version>/main/pg_hba.conf
```

Find: 
```
local   all             all                                     peer
```

and replace to:
```
local   all             all                                     scram-sha-256
```

and **restart** Postgres:
```bash
sudo systemctl restart postgresql
```

# Postgres (prod)

## Create User
`CREATE USER muj_rails_user WITH PASSWORD 'moje_super_tajne_heslo';`

## Create database
```sql
CREATE DATABASE muj_eshop OWNER muj_rails_user;
```

## Postgres (local)
```bash
# Přepnutí na postgres uživatele a spuštění konzole
sudo -i -u postgres psql
```
```sql
-- Vytvoření databáze vlastněné uživatelem postgres
CREATE DATABASE muj_eshop OWNER postgres;
```

## Postgres - Login to interactive shell (prod || local)
```bash
# user
psql -d muj_eshop -U muj_rails_user -W
```

```bash
# nebo su
su - postgres
psql
```

# Ruby (with RVM)

```bash
sudo apt install curl gnupg2 -y
gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm requirements
rvm install 3.3.7
rvm use 3.3.7 --default
ruby -v
```

Fix **RVM** - add this line to `~/.bashrc`:
```bash
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session as a function
```

# Rails
```bash
gem install rails
```

or specific **version**
```bash
gem install rails --version=7.0.0
```

## Create project
```bash
rails new eshop --database=postgresql
cd eshop
```

### Set Database connection
Update `config/database.yml`:
```yaml
development:
  <<: *default
  database: eshop_development
  username: rails_user
  password: PASSWORD
  host: localhost

test:
  <<: *default
  database: eshop_test
  username: rails_user
  password: PASSWORD
  host: localhost
```

## Create database
```bash
rails db:create
```

## Run server
```bash
rails server
```

## Create Model Category
```bash
rails generate model Category name:string description:text
```

**Description:**
* `rails generate model` command
* `Category` model name
* `name:string` column *name*, type *string*
* `description:text` column *description*, type *text*

This command generate:
* `app/models/category.rb` model file
* `db/migrate/<timestamp>_create_categories.rb` migration file for create table *categories*

## Migration
```bash
rails db:migrate
```

## Check in Rails console
```bash
rails console
```

**Create category** - *If you want*
```ruby
Category.create(name: "Electronics", description: "All kinds of electronics")
```

scaffold
## Create scaffolds for Eshop
```bash
rails g scaffold Category name:string description:text
rails g scaffold Product name:string description:text price:decimal category:references
rails g scaffold Rating value:integer product:references user:references
rails g scaffold User username:string email:string
rails g scaffold Cart user:references
rails g scaffold Order total_price:decimal status:string user:references
rails g scaffold LineItem product:references quantity:integer price:decimal buyable:references{polymorphic}
```

If you want create **Controller** and **Views** manually create only **Models**
```bash
rails generate model User username:string email:string
rails generate model Product name:string description:text price:decimal category:references
rails generate model Comment body:text product:references user:references
rails generate model Rating value:integer product:references user:references
```

## Update Models
Update `app/models/user.rb`:
```ruby
class User < ApplicationRecord
  has_many :carts
  has_many :orders
  has_many :comments
  has_many :ratings
end
```

and `app/models/product.rb`:
```ruby
class Product < ApplicationRecord
  belongs_to :category
  has_many :comments
  has_many :ratings
end
```

`app/models/comment.rb`:
```ruby
class Comment < ApplicationRecord
  belongs_to :product
  belongs_to :user
end
```

`app/models/rating.rb`:
```ruby
class Rating < ApplicationRecord
  belongs_to :product
  belongs_to :user
end
```

`app/models/cart.rb`:
```ruby
class Cart < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user, optional: true # optional: true, aby košík mohli mít i hosté
end
```

``:
```ruby
class Order < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user
end
```

`app/models/line_item.rb`:
```ruby
class LineItem < ApplicationRecord
  belongs_to :product
  belongs_to :buyable, polymorphic: true
end
```



## Add test data
```ruby
Category.create(name: "Electronics", description: "All kinds of electronics")
Category.create(name: "Food", description: "Food processed and unprocessed")

electronics = Category.find_by(name: "Electronics")
food = Category.find_by(name: "Food")

user1 = User.create!(username: "jan.novak", email: "jan.novak@example.com")
user2 = User.create!(username: "marie.novotna", email: "marie.novotna@example.com")

product1 = Product.create!(
  name: "Smartphone X",
  description: "A powerful new smartphone.",
  price: 999.99,
  category: electronics
)
product2 = Product.create!(
  name: "Organic Pasta",
  description: "Handmade organic pasta from Italy.",
  price: 5.99,
  category: food
)
product1.comments.create!(
  user: user1,
  body: "Skvělý telefon, výborný výkon."
)
product1.comments.create!(
  user: user2,
  body: "Fotoaparát je super, ale baterie by mohla vydržet déle."
)
product1.ratings.create!(
  user: user1,
  value: 5
)
product1.ratings.create!(
  user: user2,
  value: 4
)
product2.comments.create!(
  user: user2,
  body: "Chutná a kvalitní pasta, doporučuji!"
)
product2.ratings.create!(
  user: user1,
  value: 5
)

# Test
puts product1.inspect
puts product1.comments.inspect
puts product1.ratings.inspect
```

Set root *layout* and create **Controller**:
`config/routes.rb`:
```ruby
Rails.application.routes.draw do
  root "posts#index"
end
```

```bash
rails generate controller posts index
```

Run server and test in Browser:
`rails s`
and check:
`http://localhost:3000/categories` and `http://localhost:3000/products`


## Add functionalities

`app/controllers/application_controller.rb`:
```ruby
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
```

`app/controllers/line_items_controller.rb`:
```ruby
class LineItemsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    @line_item = current_cart.add_product(product, params[:quantity])

    if @line_item.save
      redirect_to cart_path(current_cart), notice: "Product added to cart."
    else
      redirect_to product_path(product), alert: "Cannot add Product to cart."
    end
  end
end
```

`app/controllers/carts_controller.rb`:
```ruby
class CartsController < ApplicationController
  def show
    @cart = current_cart
  end
end
```

`app/controllers/orders_controller.rb`:
```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create_from_cart(current_cart, current_user)

    if @order.persisted?
      # Odstranění košíku ze session
      session[:cart_id] = nil
      redirect_to order_path(@order), notice: "Objednávka byla úspěšně vytvořena."
    else
      redirect_to cart_path, alert: "Chyba při vytváření objednávky."
    end
  end
end
```

`app/models/order.rb`:
```ruby
class Order < ApplicationRecord
  ...

  def self.create_from_cart(cart, user)
    # Create order only from cart what is not empty
    return nil if cart.nil? || cart.line_items.empty?

    order = new(user: user, total_price: cart.total_price, status: "pending")
    cart.line_items.each do |line_item|
      order.line_items.build(
        product: line_item.product,
        quantity: line_item.quantity,
        price: line_item.price
      )
    end

    if order.save
      cart.destroy! # Rmove cart after create orader
      order
    else
      nil
    end
  end
end
```

`app/models/cart.rb`:
```ruby
class Cart < ApplicationRecord
  ...

  def add_product(product, quantity)
    current_item = line_items.find_by(product_id: product.id)
    if current_item
      current_item.quantity += quantity.to_i
    else
      current_item = line_items.build(product_id: product.id, quantity: quantity.to_i, price: product.price)
    end
    current_item
  end

  def total_price
    line_items.to_a.sum(&:total_price)
  end
end
```

`app/controllers/carts_controller.rb`:
```ruby
class CartsController < ApplicationController
  before_action :set_cart, only: %i[ show ]

  def show; end

  private

  def set_cart
    @cart = find_or_create_cart # Use method from ApplicationController
  end
end
```

`app/controllers/line_items_controller.rb`:
```ruby
class LineItemsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    @line_item = current_cart.add_product(product, params[:quantity])

    if @line_item.save
      redirect_to cart_path(current_cart), notice: "Produkt byl úspěšně přidán do košíku."
    else
      redirect_to product_path(product), alert: "Chyba při přidávání produktu."
    end
  end

  def update
    @line_item = current_cart.line_items.find(params[:id])
    if @line_item.update(line_item_params)
      redirect_to cart_path(current_cart), notice: "Množství bylo aktualizováno."
    else
      redirect_to cart_path(current_cart), alert: "Chyba při aktualizaci."
    end
  end

  def destroy
    @line_item = current_cart.line_items.find(params[:id])
    @line_item.destroy
    redirect_to cart_path(current_cart), notice: "Položka byla odstraněna."
  end

  private

  def line_item_params
    params.require(:line_item).permit(:quantity)
  end
end
```

`app/controllers/orders_controller.rb`:
```ruby
class OrdersController < ApplicationController
  def create
    @order = Order.create_from_cart(current_cart, current_user) # current_user by měl být autentizovaný

    if @order
      redirect_to @order, notice: "Objednávka byla úspěšně vytvořena."
    else
      redirect_to cart_path(current_cart), alert: "Košík je prázdný, objednávka nebyla vytvořena."
    end
  end

  def show
    @order = Order.find(params[:id])
  end
end
```

`app/views/products/show.html.erb`:
```html
<p>
  <strong>Name:</strong>
  <%= @product.name %>
</p>

<p>
  <strong>Description:</strong>
  <%= @product.description %>
</p>

<p>
  <strong>Price:</strong>
  <%= @product.price %>
</p>

<%= form_tag cart_line_items_path(current_cart), method: :post do %>
  <%= hidden_field_tag :product_id, @product.id %>
  <%= number_field_tag :quantity, 1, min: 1 %>
  <%= submit_tag "Přidat do košíku" %>
<% end %>

<%= link_to 'Zpět', products_path %>
```

`app/views/carts/show.html.erb`:
```html
<h1>Váš nákupní košík</h1>

<table>
  <thead>
    <tr>
      <th>Produkt</th>
      <th>Množství</th>
      <th>Cena</th>
      <th>Celkem</th>
      <th></th>
    </tr>
  </thead>

  <tbody>
    <% @cart.line_items.each do |item| %>
      <tr>
        <td><%= item.product.name %></td>
        <td>
          <%= form_with(model: item, url: cart_line_item_path(current_cart, item), method: :patch) do |form| %>
            <%= form.number_field :quantity, min: 1 %>
            <%= form.submit "Aktualizovat", class: "button" %>
          <% end %>
        </td>
        <td><%= item.price %></td>
        <td><%= item.total_price %></td>
        <td><%= button_to "Odstranit", cart_line_item_path(current_cart, item), method: :delete %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<p><strong>Celkem:</strong> <%= @cart.total_price %></p>

<% if @cart.line_items.any? %>
  <%= button_to "Objednat", orders_path, method: :post %>
<% end %>

<%= link_to 'Zpět', root_path %>
```

`app/views/orders/show.html.erb`:
```html
<h1>Objednávka č. <%= @order.id %></h1>

<table>
  <thead>
    <tr>
      <th>Produkt</th>
      <th>Množství</th>
      <th>Cena</th>
      <th>Celkem</th>
    </tr>
  </thead>

  <tbody>
    <% @order.line_items.each do |item| %>
      <tr>
        <td><%= item.product.name %></td>
        <td><%= item.quantity %></td>
        <td><%= item.price %></td>
        <td><%= item.total_price %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<p><strong>Celková cena:</strong> <%= @order.total_price %></p>

<%= link_to 'Zpět na produkty', root_path %>
```

``:
```ruby
```

``:
```ruby
```

``:
```ruby
```

``:
```ruby
```



```bash
```

```ruby
```