# III. Trailblazer Refactoring - API pro Ratings + Agregace v Trailblazer

## Vytvoříme:
* API endpoint pro seznam všech ratings
* API endpoint pro průměrné hodnocení per kategorie
* Operation pro agregaci dat

## 1. Vytvoř strukturu
```bash
mkdir -p app/concepts/rating/operation
mkdir -p app/controllers/api/v1
```

## 2. Instalace
```
# Gemfile
gem 'kaminari'  # nebo 'pagy' (rychlejší)
```

```bash
bundle install
```

## 3. Operation pro Index (seznam ratings)
```ruby
# app/concepts/rating/operation/index.rb
module Rating::Operation
  class Index < Trailblazer::Operation
    step :fetch_ratings
    step :include_associations

    def fetch_ratings(ctx, params:, **)
      # Volitelný filtr podle product_id
      if params[:product_id].present?
        ctx[:model] = Rating.where(product_id: params[:product_id])
      else
        ctx[:model] = Rating.all
      end
      true
    end

    def include_associations(ctx, **)
      # Eager loading pro výkon
      ctx[:model] = ctx[:model].includes(:product, :user)
      true
    end
  end
end
```

## 4. Operation pro agregaci (průměr per kategorie)
```ruby
# app/concepts/rating/operation/category_averages.rb
module Rating::Operation
  class CategoryAverages < Trailblazer::Operation
    step :fetch_data
    step :calculate_averages

    def fetch_data(ctx, **)
      # SQL agregace - efektivní!
      ctx[:raw_data] = Rating
        .joins(product: :category)
        .group('categories.id', 'categories.name')
        .select(
          'categories.id as category_id',
          'categories.name as category_name',
          'AVG(ratings.value) as average_rating',
          'COUNT(ratings.id) as ratings_count'
        )
      true
    end

    def calculate_averages(ctx, **)
      # Transformuj data do čitelného formátu
      ctx[:model] = ctx[:raw_data].map do |record|
        {
          category_id: record.category_id,
          category_name: record.category_name,
          average_rating: record.average_rating.to_f.round(2),
          ratings_count: record.ratings_count
        }
      end
      true
    end
  end
end
```

## 5. API Controller
```ruby
# app/controllers/api/v1/ratings_controller.rb
module Api
  module V1
    class RatingsController < ApplicationController
      # GET /api/v1/ratings
      def index
        result = Rating::Operation::Index.call(
          params: params.to_unsafe_h
        )

        if result.success?
          render json: {
            success: true,
            data: result[:model].as_json(
              only: [:id, :value, :product_id, :user_id, :created_at],
              include: {
                product: { only: [:id, :name] },
                user: { only: [:id, :email] }
              }
            )
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

## 6. Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :ratings, only: [:index] do
      collection do
        get :category_averages
      end
    end
  end
end
```

## 7. Test v konzoli/curl
```bash
# Všechna hodnocení
curl http://localhost:3000/api/v1/ratings

# Hodnocení pro konkrétní produkt
curl http://localhost:3000/api/v1/ratings?product_id=3

# Průměry per kategorie
curl http://localhost:3000/api/v1/ratings/category_averages
```

## 8. Příklad odpovědi - category_averages
```
{
  "success": true,
  "data": [
    {
      "category_id": 1,
      "category_name": "Elektronika",
      "average_rating": 4.35,
      "ratings_count": 23
    },
    {
      "category_id": 2,
      "category_name": "Oblečení",
      "average_rating": 3.89,
      "ratings_count": 15
    }
  ]
}
```

✅ Oddělená logika - fetching a agregace v operations
✅ Testovatelné - můžeš testovat operations samostatně
✅ Znovupoužitelné - použiješ stejnou operaci i pro admin dashboard
✅ Efektivní SQL - agregace přímo v databázi


# Filtering + Pagination + Tests + Docs 

## 9. Refactor Rating::Index s filtry a paginací
```ruby
# app/concepts/rating/operation/index.rb
module Rating::Operation
  class Index < Trailblazer::Operation
    step :fetch_ratings
    step :apply_filters
    step :apply_sorting
    step :paginate
    step :include_associations

    def fetch_ratings(ctx, **)
      ctx[:model] = Rating.all
      true
    end

    def apply_filters(ctx, params:, **)
      query = ctx[:model]
      
      # Filtr podle product_id
      query = query.where(product_id: params[:product_id]) if params[:product_id].present?
      
      # Filtr podle user_id
      query = query.where(user_id: params[:user_id]) if params[:user_id].present?
      
      # Filtr podle min/max hodnoty
      query = query.where('value >= ?', params[:min_rating]) if params[:min_rating].present?
      query = query.where('value <= ?', params[:max_rating]) if params[:max_rating].present?
      
      # Filtr podle data
      query = query.where('created_at >= ?', params[:from_date]) if params[:from_date].present?
      query = query.where('created_at <= ?', params[:to_date]) if params[:to_date].present?
      
      ctx[:model] = query
      true
    end

    def apply_sorting(ctx, params:, **)
      sort_by = params[:sort_by] || 'created_at'
      direction = params[:direction] || 'desc'
      
      # Whitelist povolených sloupců
      allowed_columns = %w[value created_at product_id user_id]
      sort_by = 'created_at' unless allowed_columns.include?(sort_by)
      
      direction = 'desc' unless %w[asc desc].include?(direction)
      
      ctx[:model] = ctx[:model].order("#{sort_by} #{direction}")
      true
    end

    def paginate(ctx, params:, **)
      page = params[:page] || 1
      per_page = params[:per_page] || 25
      
      # Limit per_page na max 100
      per_page = [per_page.to_i, 100].min
      
      ctx[:model] = ctx[:model].page(page).per(per_page)
      ctx[:pagination] = {
        current_page: ctx[:model].current_page,
        total_pages: ctx[:model].total_pages,
        total_count: ctx[:model].total_count,
        per_page: per_page.to_i
      }
      true
    end

    def include_associations(ctx, **)
      ctx[:model] = ctx[:model].includes(:product, :user)
      true
    end
  end
end
```

## 10. Update API Controller
```ruby
# app/controllers/api/v1/ratings_controller.rb
module Api
  module V1
    class RatingsController < ApplicationController
      # GET /api/v1/ratings
      def index
        result = Rating::Operation::Index.call(
          params: params.to_unsafe_h
        )

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

## 11. Testy - RSpec
```ruby
# spec/concepts/rating/operation/index_spec.rb
require 'rails_helper'

RSpec.describe Rating::Operation::Index do
  let(:user) { create(:user) }
  let(:category) { create(:category) }
  let(:product) { create(:product, category: category) }
  
  before do
    # Vytvoř testovací data
    create(:rating, product: product, user: user, value: 5, created_at: 2.days.ago)
    create(:rating, product: product, user: user, value: 3, created_at: 1.day.ago)
    create(:rating, product: product, user: user, value: 4, created_at: Time.current)
  end

  describe 'bez filtrů' do
    it 'vrátí všechna hodnocení' do
      result = described_class.call(params: {})
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(3)
    end
  end

  describe 'filtr podle product_id' do
    it 'vrátí jen hodnocení daného produktu' do
      result = described_class.call(params: { product_id: product.id })
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(3)
      expect(result[:model].pluck(:product_id).uniq).to eq([product.id])
    end
  end

  describe 'filtr podle min_rating' do
    it 'vrátí jen hodnocení >= 4' do
      result = described_class.call(params: { min_rating: 4 })
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
      expect(result[:model].pluck(:value)).to match_array([4, 5])
    end
  end

  describe 'filtr podle max_rating' do
    it 'vrátí jen hodnocení <= 3' do
      result = described_class.call(params: { max_rating: 3 })
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(1)
      expect(result[:model].first.value).to eq(3)
    end
  end

  describe 'filtr podle data' do
    it 'vrátí jen hodnocení od včerejška' do
      result = described_class.call(params: { from_date: 1.day.ago })
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
    end
  end

  describe 'řazení' do
    it 'seřadí podle value vzestupně' do
      result = described_class.call(params: { sort_by: 'value', direction: 'asc' })
      
      expect(result.success?).to be true
      expect(result[:model].pluck(:value)).to eq([3, 4, 5])
    end
  end

  describe 'stránkování' do
    it 'vrátí první stránku s 2 položkami' do
      result = described_class.call(params: { page: 1, per_page: 2 })
      
      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
      expect(result[:pagination][:current_page]).to eq(1)
      expect(result[:pagination][:total_pages]).to eq(2)
      expect(result[:pagination][:total_count]).to eq(3)
    end
  end
end
```

## 12. Test pro CategoryAverages
```ruby
# spec/concepts/rating/operation/category_averages_spec.rb
require 'rails_helper'

RSpec.describe Rating::Operation::CategoryAverages do
  let(:user) { create(:user) }
  let(:category1) { create(:category, name: 'Elektronika') }
  let(:category2) { create(:category, name: 'Oblečení') }
  let(:product1) { create(:product, category: category1) }
  let(:product2) { create(:product, category: category2) }
  
  before do
    create(:rating, product: product1, value: 5)
    create(:rating, product: product1, value: 3)
    create(:rating, product: product2, value: 4)
  end

  it 'vypočítá průměry per kategorie' do
    result = described_class.call(params: {})
    
    expect(result.success?).to be true
    expect(result[:model].count).to eq(2)
    
    elektronika = result[:model].find { |c| c[:category_name] == 'Elektronika' }
    expect(elektronika[:average_rating]).to eq(4.0)
    expect(elektronika[:ratings_count]).to eq(2)
    
    obleceni = result[:model].find { |c| c[:category_name] == 'Oblečení' }
    expect(obleceni[:average_rating]).to eq(4.0)
    expect(obleceni[:ratings_count]).to eq(1)
  end
end
```

## 13. Factory (pro testy)
```ruby
# spec/factories/ratings.rb
FactoryBot.define do
  factory :rating do
    association :product
    association :user
    value { rand(1..5) }
  end
end
```

## 14. API Dokumentace
`docs/api/ratings.md`

# Ratings API

## GET /api/v1/ratings

Vrací seznam hodnocení s možností filtrování, řazení a stránkování.

### Query parametry

| Parametr | Typ | Popis |
|----------|-----|-------|
| `product_id` | integer | Filtr podle produktu |
| `user_id` | integer | Filtr podle uživatele |
| `min_rating` | integer (1-5) | Minimální hodnocení |
| `max_rating` | integer (1-5) | Maximální hodnocení |
| `from_date` | date (YYYY-MM-DD) | Od data |
| `to_date` | date (YYYY-MM-DD) | Do data |
| `sort_by` | string | Řazení (value, created_at, product_id, user_id) |
| `direction` | string | Směr (asc, desc) |
| `page` | integer | Číslo stránky (default: 1) |
| `per_page` | integer | Počet na stránku (default: 25, max: 100) |

### Příklady
```bash
# Všechna hodnocení
GET /api/v1/ratings

# Hodnocení produktu 3 s min. 4 hvězdičkami
GET /api/v1/ratings?product_id=3&min_rating=4

# Druhá stránka, 10 na stránku, seřazeno podle hodnoty
GET /api/v1/ratings?page=2&per_page=10&sort_by=value&direction=desc

# Hodnocení za poslední týden
GET /api/v1/ratings?from_date=2025-10-16
```

### Odpověď
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "value": 5,
      "product_id": 3,
      "user_id": 1,
      "created_at": "2025-10-22T21:30:00Z",
      "product": {
        "id": 3,
        "name": "iPhone 15"
      },
      "user": {
        "id": 1,
        "email": "user@example.com"
      }
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 123,
    "per_page": 25
  }
}
```

---

## GET /api/v1/ratings/category_averages

Vrací průměrné hodnocení pro každou kategorii.

### Odpověď
```json
{
  "success": true,
  "data": [
    {
      "category_id": 1,
      "category_name": "Elektronika",
      "average_rating": 4.35,
      "ratings_count": 23
    }
  ]
}
```

## 15. Spusť testy
```bash
bundle exec rspec spec/concepts/rating/
```

✅ **Filtrování** (*product*, *user*, *rating*, *datum*)
✅ **Řazení** (*value*, *datum*, ...)
✅ **Stránkování** (max 100/stránka)
✅ **Testy** (*RSpec*)
✅ **Dokumentace** (*Markdown*)

## 16. Fix testy
Add to **Gemfile**
```bash
group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end
```

```bash
bundle install
```

Initialize **RSpec tests**
```bash
rails generate rspec:install
```

Přidej konfiguraci do `spec/rails_helper.rb`:
Na začátek souboru (za `require 'rspec/rails'`)
```ruby
require 'factory_bot_rails'

RSpec.configure do |config|
  # Přidej tenhle řádek:
  config.include FactoryBot::Syntax::Methods
  
  # ... zbytek konfigurace
end
```

Create `spec/factories/categories.rb`:
```ruby
FactoryBot.define do
  factory :category do
    name { "Test Category" }
  end
end
```

and `spec/factories/products.rb`:
```ruby
FactoryBot.define do
  factory :product do
    name { "Test Product" }
    description { "Test description" }
    price { 100.0 }
    association :category
  end
end
```

`spec/factories/users.rb`:
```ruby
FactoryBot.define do
  factory :user do
    email { "user@example.com" }
    # Přidej další povinné atributy podle tvého User modelu
  end
end
```

`spec/factories/ratings.rb`:
```ruby
FactoryBot.define do
  factory :rating do
    value { rand(1..5) }
    association :product
    association :user
  end
end
```

Run Tests again.
```bash
bundle exec rspec spec/concepts/rating/
```