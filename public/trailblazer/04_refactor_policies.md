# IV. Trailblazer Refactoring - Policies + Roles + Brands - Kompletní implementace

## 1. Vytvoř migrace

```bash
rails g migration AddRoleToUsers role:string
rails g model Brand name:string
rails g migration CreateBrandsUsers brand:references user:references
rails g migration AddBrandToProducts brand:references
```

Uprav migrace:
`db/migrate/..._add_role_to_users.rb`
```ruby
class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: 'customer', null: false
    add_index :users, :role
  end
end
```

`db/migrate/..._create_brands_users.rb`

```ruby
class CreateBrandsUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :brands_users do |t|
      t.references :brand, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :brands_users, [:brand_id, :user_id], unique: true
  end
end
```

`db/migrate/..._add_brand_to_products.rb`

```ruby
class AddBrandToProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :products, :brand, foreign_key: true
  end
end
```

```bash
rails db:migrate
```

## 2. Modely
`app/models/user.rb`

```ruby
class User < ApplicationRecord
  has_one :cart
  has_many :orders
  has_many :ratings
  has_many :comments
  
  # Brands pro suppliers
  has_many :brands_users
  has_many :brands, through: :brands_users
  
  # Role enum
  enum role: {
    customer: 'customer',
    supplier: 'supplier',
    admin: 'admin'
  }
  
  validates :role, presence: true, inclusion: { in: roles.keys }
end
```

`app/models/brand.rb`

```ruby
class Brand < ApplicationRecord
  has_many :products
  has_many :brands_users
  has_many :users, through: :brands_users
  
  validates :name, presence: true, uniqueness: true
end
```

`app/models/brands_user.rb`

```ruby
class BrandsUser < ApplicationRecord
  belongs_to :brand
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :brand_id }
end
```

`app/models/product.rb`

```ruby
class Product < ApplicationRecord
  belongs_to :category
  belongs_to :brand, optional: true
  has_many :comments
  has_many :ratings
  
  validates :name, :price, presence: true
end
```

`app/models/order.rb`

```ruby
class Order < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user
  
  validates :user, presence: true
end
```

## 3. Policies pomocí Pundit
Přidej gem:

```yaml
# Gemfile
gem 'pundit'
```

```bash
bundle install
rails g pundit:install
```

## 4. ApplicationController update
`app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  allow_browser versions: :modern
  helper_method :current_cart, :current_user
  before_action :set_current_cart
  
  # Pundit errors
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
    # Pro development - simulace přihlášeného usera
    # V produkci použij Devise nebo jinou autentizaci
    @current_user ||= User.find_by(id: session[:user_id]) || User.first
  end
  
  private
  
  def user_not_authorized
    flash[:alert] = "Nemáte oprávnění k této akci."
    redirect_to(request.referrer || root_path)
  end
end
```

## 5. Product Policy
`app/policies/product_policy.rb`

```ruby
class ProductPolicy < ApplicationPolicy
  def index?
    true # Všichni vidí produkty
  end
  
  def show?
    true
  end
  
  def create?
    user.admin? || user.supplier?
  end
  
  def update?
    user.admin? || (user.supplier? && user_owns_brand?)
  end
  
  def destroy?
    user.admin? || (user.supplier? && user_owns_brand?)
  end
  
  private
  
  def user_owns_brand?
    return false unless record.brand_id
    user.brand_ids.include?(record.brand_id)
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.supplier?
        scope.where(brand_id: user.brand_ids)
      else
        scope.all # Customers vidí všechny produkty
      end
    end
  end
end
```

## 6. Order Policy
`app/policies/order_policy.rb`

```ruby
class OrderPolicy < ApplicationPolicy
  def index?
    true # Každý vidí objednávky (filtrované v scope)
  end
  
  def show?
    user.admin? || record.user_id == user.id
  end
  
  def create?
    true # Každý může vytvořit objednávku
  end
  
  def update?
    user.admin?
  end
  
  def destroy?
    user.admin?
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
```

## 7. Update Controllers
`app/controllers/products_controller.rb`

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = policy_scope(Product)
  end

  def show
    authorize @product
  end

  def new
    @product = Product.new
    authorize @product
  end

  def edit
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    authorize @product
    
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @product
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_path, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  
  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.expect(product: [ :name, :description, :price, :category_id, :brand_id ])
  end
end
```

`app/controllers/orders_controller.rb`
```ruby
class OrdersController < ApplicationController
  before_action :set_order, only: %i[ show edit update destroy ]

  def index
    @orders = policy_scope(Order)
  end

  def show
    authorize @order
  end

  def create
    result = Order::Operation::Create.call(
      params: {},
      current_cart: current_cart,
      current_user: current_user
    )

    if result.success?
      redirect_to result[:model], notice: "Objednávka byla úspěšně vytvořena."
    else
      redirect_to cart_path(current_cart), alert: "Košík je prázdný."
    end
  end

  def update
    authorize @order
    # ... zbytek
  end

  def destroy
    authorize @order
    # ... zbytek
  end

  private
  
  def set_order
    @order = Order.find(params[:id])
  end
end
```

## 8. Seeds - Testovací data
`db/seeds.rb`

```ruby
# Cleanup
BrandsUser.destroy_all
Brand.destroy_all
User.destroy_all
Product.destroy_all
Category.destroy_all

# Brands
food_inc = Brand.create!(name: 'Food Inc.')
smart_inc = Brand.create!(name: 'Smart Inc.')
nestle = Brand.create!(name: 'Nestle')
pepsi = Brand.create!(name: 'Pepsi')

puts "✅ Vytvořeny značky: #{Brand.pluck(:name).join(', ')}"

# Users
admin = User.create!(email: 'admin@admin.com', role: 'admin')
customer1 = User.create!(email: 'customer1@test.com', role: 'customer')
customer2 = User.create!(email: 'customer2@test.com', role: 'customer')

supplier_food = User.create!(email: 'supplier@foodinc.com', role: 'supplier')
supplier_food.brands << food_inc
supplier_food.brands << nestle

supplier_smart = User.create!(email: 'supplier@smartinc.com', role: 'supplier')
supplier_smart.brands << smart_inc
supplier_smart.brands << pepsi

puts "✅ Vytvořeni uživatelé:"
puts "  Admin: admin@admin.com"
puts "  Customers: customer1@test.com, customer2@test.com"
puts "  Supplier (Food Inc., Nestle): supplier@foodinc.com"
puts "  Supplier (Smart Inc., Pepsi): supplier@smartinc.com"

# Categories
electronics = Category.create!(name: 'Elektronika')
food = Category.create!(name: 'Potraviny')

puts "✅ Vytvořeny kategorie: #{Category.pluck(:name).join(', ')}"

# Products
Product.create!(
  name: 'Nescafe',
  description: 'Instantní káva',
  price: 99,
  category: food,
  brand: nestle
)

Product.create!(
  name: 'Pepsi Cola',
  description: 'Osvěžující nápoj',
  price: 25,
  category: food,
  brand: pepsi
)

Product.create!(
  name: 'Smart Phone',
  description: 'Chytrý telefon',
  price: 15999,
  category: electronics,
  brand: smart_inc
)

puts "✅ Vytvořeny produkty: #{Product.count}"

puts "\n🎉 Seeding dokončen!"
```

```bash
rails db:seed
```

## 9. Přepínání uživatelů (pro development)
`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:switch_user]
  
  def switch_user
    user = User.find(params[:user_id])
    session[:user_id] = user.id
    redirect_to root_path, notice: "Přepnuto na: #{user.email} (#{user.role})"
  end
end
```

`config/routes.rb`

```ruby
post 'switch_user/:user_id', to: 'sessions#switch_user', as: :switch_user
```

Přidej do layoutu (development only):

```html
<!-- app/views/layouts/application.html.erb -->
<% if Rails.env.development? %>
  <div style="background: yellow; padding: 10px;">
    Přihlášen jako: <%= current_user.email %> (<%= current_user.role %>)
    | Přepnout na:
    <% User.all.each do |u| %>
      <%= button_to u.email, switch_user_path(u), method: :post, style: "display: inline;" %>
    <% end %>
  </div>
<% end %>
```

## 10. Testy pro Policies
`spec/policies/product_policy_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe ProductPolicy do
  subject { described_class }

  let(:admin) { create(:user, role: 'admin') }
  let(:customer) { create(:user, role: 'customer') }
  let(:supplier) { create(:user, role: 'supplier') }
  let(:brand) { create(:brand) }
  let(:product) { create(:product, brand: brand) }

  before do
    supplier.brands << brand
  end

  permissions :create? do
    it "povolí adminovi" do
      expect(subject).to permit(admin, Product.new)
    end

    it "povolí supplierovi" do
      expect(subject).to permit(supplier, Product.new)
    end

    it "zakáže customerovi" do
      expect(subject).not_to permit(customer, Product.new)
    end
  end

  permissions :update?, :destroy? do
    it "povolí adminovi" do
      expect(subject).to permit(admin, product)
    end

    it "povolí supplierovi vlastní značky" do
      expect(subject).to permit(supplier, product)
    end

    it "zakáže supplierovi cizí značky" do
      other_product = create(:product, brand: create(:brand))
      expect(subject).not_to permit(supplier, other_product)
    end

    it "zakáže customerovi" do
      expect(subject).not_to permit(customer, product)
    end
  end
end
```

✅ Role (customer, supplier, admin)
✅ Brands + vazby na users
✅ Policies (Pundit)
✅ Supplier vidí jen své značky
✅ Customer vidí jen své objednávky
✅ Admin vidí vše
✅ Seeds s testovacími daty
✅ Testy

```bash
bundle exec rspec spec/policies/
```
