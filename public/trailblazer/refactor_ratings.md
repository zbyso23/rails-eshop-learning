# Rating::Create v Trailblazer - Jednoduchý příklad

Rating je perfektní na ukázku! Jednoduchý **CRUD** bez složité logiky.

## 1. Vytvoř strukturu
```bash
mkdir -p app/concepts/rating/operation
mkdir -p app/concepts/rating/contract
```

2. Operation - Rating::Create
```ruby
# app/concepts/rating/operation/create.rb
module Rating::Operation
  class Create < Trailblazer::Operation
    step :model
    step :contract_build
    step :contract_validate
    step :contract_sync
    step :assign_user
    step :persist

    def model(ctx, **)
      ctx[:model] = Rating.new
    end

    def contract_build(ctx, **)
      ctx[:contract] = Rating::Contract::Create.new(ctx[:model])
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params[:rating])
    end

    def contract_sync(ctx, **)
      ctx[:contract].sync
      true
    end

    def assign_user(ctx, current_user:, **)
      ctx[:model].user = current_user
      true
    end

    def persist(ctx, **)
      ctx[:model].save
    end
  end
end
```

## 3. Contract - Validace
```ruby
# app/concepts/rating/contract/create.rb
module Rating::Contract
  class Create < Reform::Form
    property :value
    property :product_id

    validates :value, presence: true, 
                      numericality: { 
                        only_integer: true, 
                        greater_than_or_equal_to: 1, 
                        less_than_or_equal_to: 5 
                      }
    validates :product_id, presence: true
  end
end
```

4. Refactor Controller
```ruby
# app/controllers/ratings_controller.rb
class RatingsController < ApplicationController
  # POST /ratings
  def create
    result = Rating::Operation::Create.call(
      params: params.to_unsafe_h,
      current_user: current_user
    )

    respond_to do |format|
      if result.success?
        @rating = result[:model]
        format.html { redirect_to product_path(@rating.product), notice: "Hodnocení bylo přidáno." }
        format.json { render :show, status: :created, location: @rating }
      else
        format.html { 
          @product = Product.find(params[:rating][:product_id])
          render 'products/show', status: :unprocessable_entity 
        }
        format.json { render json: result[:contract].errors, status: :unprocessable_entity }
      end
    end
  end

  # Ostatní akce zatím bez změny
  def index
    @ratings = Rating.all
  end

  # ...
end
```

## 5. Přidej Rating do Product show
```html
# app/views/products/show.html.erb
<%= render @product %>

<h2>Hodnocení (Ratings)</h2>

<% if @product.ratings.any? %>
  <ul>
    <% @product.ratings.each do |rating| %>
      <li>
        <strong><%= rating.user_id %></strong>: 
        <%= "⭐" * rating.value %> (<%= rating.value %>/5)
      </li>
    <% end %>
  </ul>
  
  <p><strong>Průměr:</strong> <%= @product.ratings.average(:value).round(1) %>/5</p>
<% else %>
  <p>Zatím žádné hodnocení.</p>
<% end %>

<h3>Přidat hodnocení</h3>
<%= form_with(model: Rating.new, url: product_ratings_path(product)) do |form| %>
  <%= form.hidden_field :product_id, value: @product.id %>
  
  <%= form.label :value, "Hodnocení (1-5):" %>
  <%= form.number_field :value, min: 1, max: 5, required: true %>
  
  <%= form.submit "Ohodnotit" %>
<% end %>

<div>
  <%= link_to "Edit this product", edit_product_path(@product) %> |
  <%= link_to "Back to products", products_path %>
  <%= button_to "Destroy this product", @product, method: :delete %>
</div>
```

## 6. Upravit routes (pokud chceš nested)
```ruby
# config/routes.rb
resources :products do
  resources :ratings, only: [ :create ]
end

# odstranit
resources :ratings
```

## 7. Změna
✅ Operation se stará o logiku vytvoření ratingu
✅ Contract validuje vstup (1-5, product musí existovat)
✅ Controller je tenký - jen volá operaci
✅ View zobrazuje ratings + formulář

**Výhody:**

**Validace** je na jednom místě (*contract*), ne v **modelu**
**Logika** (přiřazení *usera*) je v *operaci*, ne v **controlleru**
**Testování** - otestuješ *operaci* samostatně
**API** - můžeš použít stejnou *operaci* pro **API endpoint**


```ruby
```

```ruby
```

```ruby
```
