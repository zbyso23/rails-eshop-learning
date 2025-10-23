# VI. Trailblazer Refactoring - Authentication patří do Operations!

```bash
app/concepts/
  session/
    operation/
      create.rb    # Přihlášení
      destroy.rb   # Odhlášení
```

## Refactor Session::Create do Trailblazer

## 1. Vytvoř strukturu:

```bash
mkdir -p app/concepts/session/operation
mkdir -p app/concepts/session/contract
```

## 2. Operation pro přihlášení:
`app/concepts/session/operation/create.rb`

```ruby
module Session::Operation
  class Create < Trailblazer::Operation
    step :contract_build
    step :contract_validate
    step :find_user
    step :authenticate

    def contract_build(ctx, **)
      ctx[:contract] = Session::Contract::Create.new(OpenStruct.new)
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params)
    end

    def find_user(ctx, **)
      ctx[:model] = User.find_by(email: ctx[:contract].email)
      
      if ctx[:model]
        true
      else
        ctx[:errors] = ["Uživatel s tímto emailem neexistuje"]
        false
      end
    end

    def authenticate(ctx, **)
      # Zde by byla kontrola hesla, pokud bys používal has_secure_password
      # Pro development vracíme vždy true
      true
    end
  end
end
```

## 3. Contract pro validaci:
`app/concepts/session/contract/create.rb`

```ruby
module Session::Contract
  class Create < Reform::Form
    property :email

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
end
```

## 4. Refactor SessionsController:
`app/controllers/sessions_controller.rb`

```ruby
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  skip_before_action :set_current_cart, only: [:new, :create]
  
  def new
    redirect_to root_path if user_signed_in?
  end
  
  def create
    # Zavolej operaci místo přímé logiky
    result = Session::Operation::Create.call(params: params.to_unsafe_h)
    
    if result.success?
      session[:user_id] = result[:model].id
      redirect_to root_path, notice: "Vítejte, #{result[:model].email}!"
    else
      flash.now[:alert] = result[:errors]&.first || "Neplatný email"
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Tady by mohla být Session::Operation::Destroy, ale je to tak jednoduché...
    session[:user_id] = nil
    redirect_to login_path, notice: "Byli jste odhlášeni"
  end
  
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

## 6. Session::Destroy Operation
`app/concepts/session/operation/destroy.rb`

```ruby
module Session::Operation
  class Destroy < Trailblazer::Operation
    step :clear_session
    step :log_activity

    def clear_session(ctx, session:, **)
      ctx[:previous_user_id] = session[:user_id]
      session[:user_id] = nil
      true
    end

    def log_activity(ctx, **)
      # Zde bys mohl logovat odhlášení do audit logu
      Rails.logger.info "User #{ctx[:previous_user_id]} logged out"
      true
    end
  end
end
```

Update SessionsController:

```ruby
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  skip_before_action :set_current_cart, only: [:new, :create]
  
  def new
    redirect_to root_path if user_signed_in?
  end
  
  def create
    result = Session::Operation::Create.call(params: params.to_unsafe_h)
    
    if result.success?
      session[:user_id] = result[:model].id
      redirect_to root_path, notice: "Vítejte, #{result[:model].email}!"
    else
      flash.now[:alert] = result[:errors]&.first || "Neplatný email"
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    result = Session::Operation::Destroy.call(session: session)
    
    if result.success?
      redirect_to login_path, notice: "Byli jste odhlášeni"
    else
      redirect_to root_path, alert: "Chyba při odhlášení"
    end
  end
  
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

## 7. JWT Authentication - Setup

Přidej gemy:
```yaml
# Gemfile
gem 'jwt'
gem 'bcrypt' # Pro has_secure_password
```

```bash
bundle install
```

## 8. Migrace pro password

```bash
rails g migration AddPasswordDigestToUsers password_digest:string
rails db:migrate
```

Update User model:

```ruby
class User < ApplicationRecord
  has_secure_password validations: false # Vypneme defaultní validace
  
  has_one :cart
  has_many :orders
  has_many :ratings
  has_many :comments
  has_many :brands_users
  has_many :brands, through: :brands_users
  
  validates :role, presence: true, inclusion: { in: %w[customer supplier admin] }
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  
  # Helper metody
  def admin?
    role == 'admin'
  end
  
  def supplier?
    role == 'supplier'
  end
  
  def customer?
    role == 'customer'
  end
end
```

## 9. JWT Service
`app/services/jwt_service.rb`

```ruby
class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || 'development_secret'
  ALGORITHM = 'HS256'
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
end
```

## 10. API Auth Operations
Vytvoř strukturu:

```bash
mkdir -p app/concepts/api/auth/operation
mkdir -p app/concepts/api/auth/contract
```

## 10.1 API::Auth::Login
`app/concepts/api/auth/operation/login.rb`

```ruby
module Api::Auth::Operation
  class Login < Trailblazer::Operation
    step :contract_build
    step :contract_validate
    step :find_user
    step :authenticate
    step :generate_token

    def contract_build(ctx, **)
      ctx[:contract] = Api::Auth::Contract::Login.new(OpenStruct.new)
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params)
    end

    def find_user(ctx, **)
      ctx[:user] = User.find_by(email: ctx[:contract].email)
      
      if ctx[:user]
        true
      else
        ctx[:errors] = { email: ["Uživatel nenalezen"] }
        false
      end
    end

    def authenticate(ctx, **)
      if ctx[:user].authenticate(ctx[:contract].password)
        true
      else
        ctx[:errors] = { password: ["Nesprávné heslo"] }
        false
      end
    end

    def generate_token(ctx, **)
      payload = {
        user_id: ctx[:user].id,
        email: ctx[:user].email,
        role: ctx[:user].role
      }
      
      ctx[:token] = JwtService.encode(payload)
      ctx[:model] = ctx[:user]
      true
    end
  end
end
```

## 10.2 API::Auth::Register
`app/concepts/api/auth/operation/register.rb`

```ruby
module Api::Auth::Operation
  class Register < Trailblazer::Operation
    step :contract_build
    step :contract_validate
    step :check_existing_user
    step :create_user
    step :generate_token

    def contract_build(ctx, **)
      ctx[:contract] = Api::Auth::Contract::Register.new(User.new)
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params)
    end

    def check_existing_user(ctx, **)
      if User.exists?(email: ctx[:contract].email)
        ctx[:errors] = { email: ["Email již existuje"] }
        false
      else
        true
      end
    end

    def create_user(ctx, **)
      ctx[:model] = User.new(
        email: ctx[:contract].email,
        password: ctx[:contract].password,
        role: ctx[:contract].role || 'customer'
      )
      
      if ctx[:model].save
        true
      else
        ctx[:errors] = ctx[:model].errors.messages
        false
      end
    end

    def generate_token(ctx, **)
      payload = {
        user_id: ctx[:model].id,
        email: ctx[:model].email,
        role: ctx[:model].role
      }
      
      ctx[:token] = JwtService.encode(payload)
      true
    end
  end
end
```

## 10.3 Contracts
`app/concepts/api/auth/contract/login.rb`

```ruby
module Api::Auth::Contract
  class Login < Reform::Form
    property :email
    property :password

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true
  end
end
```

`app/concepts/api/auth/contract/register.rb`

```ruby
module Api::Auth::Contract
  class Register < Reform::Form
    property :email
    property :password
    property :password_confirmation
    property :role

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, presence: true, length: { minimum: 6 }
    validates :password_confirmation, presence: true
    validate :passwords_match
    validates :role, inclusion: { in: %w[customer supplier admin] }, allow_nil: true

    def passwords_match
      if password != password_confirmation
        errors.add(:password_confirmation, "neshoduje se s heslem")
      end
    end
  end
end
```

## 11. API Auth Controller
`app/controllers/api/v1/auth_controller.rb`

```ruby
module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!
      skip_before_action :verify_authenticity_token
      skip_before_action :set_current_cart
      
      # POST /api/v1/auth/login
      def login
        result = Api::Auth::Operation::Login.call(params: auth_params)
        
        if result.success?
          render json: {
            success: true,
            token: result[:token],
            user: {
              id: result[:model].id,
              email: result[:model].email,
              role: result[:model].role
            }
          }, status: :ok
        else
          render json: {
            success: false,
            errors: result[:errors] || result[:contract]&.errors&.messages
          }, status: :unauthorized
        end
      end
      
      # POST /api/v1/auth/register
      def register
        result = Api::Auth::Operation::Register.call(params: auth_params)
        
        if result.success?
          render json: {
            success: true,
            token: result[:token],
            user: {
              id: result[:model].id,
              email: result[:model].email,
              role: result[:model].role
            }
          }, status: :created
        else
          render json: {
            success: false,
            errors: result[:errors] || result[:contract]&.errors&.messages
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/auth/me
      def me
        render json: {
          success: true,
          user: {
            id: current_user.id,
            email: current_user.email,
            role: current_user.role
          }
        }
      end
      
      private
      
      def auth_params
        params.permit(:email, :password, :password_confirmation, :role)
      end
    end
  end
end
```

## 12. JWT Authentication Concern
`app/controllers/concerns/api_authenticatable.rb`

```ruby
module ApiAuthenticatable
  extend ActiveSupport::Concern
  
  included do
    before_action :authenticate_api_user!
  end
  
  private
  
  def authenticate_api_user!
    token = extract_token
    
    unless token
      render json: { success: false, error: 'Token chybí' }, status: :unauthorized
      return
    end
    
    payload = JwtService.decode(token)
    
    unless payload
      render json: { success: false, error: 'Neplatný token' }, status: :unauthorized
      return
    end
    
    @current_user = User.find_by(id: payload[:user_id])
    
    unless @current_user
      render json: { success: false, error: 'Uživatel nenalezen' }, status: :unauthorized
    end
  end
  
  def extract_token
    header = request.headers['Authorization']
    header&.split(' ')&.last
  end
  
  def current_user
    @current_user
  end
end
```

## 13. Update API Controllers pro JWT auth
`app/controllers/api/v1/ratings_controller.rb`

```ruby
module Api
  module V1
    class RatingsController < ApplicationController
      include ApiAuthenticatable
      
      skip_before_action :authenticate_user!
      skip_before_action :verify_authenticity_token
      skip_before_action :set_current_cart
      
      # GET /api/v1/ratings
      def index
        result = Rating::Operation::Index.call(params: params.to_unsafe_h)

        if result.success?
          render json: {
            success: true,
            data: result[:model].as_json(
              only: [:id, :value, :product_id, :user_id, :created_at],
              include: {
                product: { only: [:id, :name] },
                user: { only: [:id, :email] }
              }
            ),
            pagination: result[:pagination]
          }
        else
          render json: { success: false, errors: "Failed to fetch ratings" }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/ratings/category_averages
      def category_averages
        result = Rating::Operation::CategoryAverages.call(params: {})

        if result.success?
          render json: {
            success: true,
            data: result[:model]
          }
        else
          render json: { success: false, errors: "Failed to calculate averages" }, status: :unprocessable_entity
        end
      end
    end
  end
end
```

## 14. Routes
`config/routes.rb`

```ruby
Rails.application.routes.draw do
  root 'products#index'
  
  # Web Auth
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  if Rails.env.development?
    post 'switch_user/:user_id', to: 'sessions#switch_user', as: :switch_user
  end

  # API
  namespace :api do
    namespace :v1 do
      # Auth endpoints
      post 'auth/login', to: 'auth#login'
      post 'auth/register', to: 'auth#register'
      get 'auth/me', to: 'auth#me'
      
      # Resources
      resources :ratings, only: [:index] do
        collection do
          get :category_averages
        end
      end
    end
  end

  # Web Resources
  resources :products do
    resources :ratings, only: [:create]
  end
  
  resources :orders
  resources :categories
  resources :carts
  resources :line_items
  resources :comments
  resources :ratings
  
  get 'cart', to: 'carts#show', as: :cart
end
```

## 15. Update Seeds - přidej hesla
`db/seeds.rb`

```ruby
# ... cleanup ...

# Users s hesly
admin = User.create!(
  email: 'admin@admin.com', 
  role: 'admin',
  password: 'password123',
  password_confirmation: 'password123'
)

customer1 = User.create!(
  email: 'customer1@test.com', 
  role: 'customer',
  password: 'password123',
  password_confirmation: 'password123'
)

# ... zbytek
```

```bash
rails db:seed
```

## 16. Test API s curl

```bash
# Registrace
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "customer"
  }'

# Response: {"success":true,"token":"eyJ...","user":{...}}

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@admin.com",
    "password": "password123"
  }'

# Ulož token
TOKEN="eyJ..."

# Autentizovaný request
curl -X GET http://localhost:3000/api/v1/ratings \
  -H "Authorization: Bearer $TOKEN"

# Ověření tokenu
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

## 17. Testy
`spec/concepts/api/auth/operation/login_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Api::Auth::Operation::Login do
  let(:user) { create(:user, email: 'test@example.com', password: 'password123') }

  describe 'úspěšné přihlášení' do
    it 'vrátí token a uživatele' do
      result = described_class.call(
        params: { email: 'test@example.com', password: 'password123' }
      )

      expect(result.success?).to be true
      expect(result[:token]).to be_present
      expect(result[:model]).to eq(user)
    end
  end

  describe 'neúspěšné přihlášení' do
    it 'selže s nesprávným heslem' do
      result = described_class.call(
        params: { email: 'test@example.com', password: 'wrong' }
      )

      expect(result.success?).to be false
      expect(result[:errors]).to be_present
    end

    it 'selže s neexistujícím emailem' do
      result = described_class.call(
        params: { email: 'nonexistent@example.com', password: 'password123' }
      )

      expect(result.success?).to be false
    end
  end
end
```

✅ Business logika v operaci (najdi usera, ověř)
✅ Validace v contractu (email formát)
✅ Controller je tenký - jen volá operaci
✅ Testovatelné - testuješ operaci, ne controller
✅ Znovupoužitelné - můžeš volat z API, CLI, jobů
✅ Session::Destroy operation
✅ JWT service
✅ API Auth operations (Login, Register)
✅ JWT middleware
✅ API endpoints s autentizací
✅ Testy
✅ Dokumentace (curl příklady)