# Trailblazer Refactoring - Order jako ukázka

Ukážu ti jeden konkrétní případ - vytvoření objednávky (`create`), abys viděl principy.
## 1. Struktura Trailblazer (TRB)

```
app/
  concepts/          # Hlavní složka pro TRB
    order/
      operation/
        create.rb    # *Business logika*
      contract/
        create.rb    # Validace (replacuje strong params)
      cell/
        index.rb     # View komponenty (optional)
        show.rb
```

### Principy Trailblazer
**Operation** = *Business logika* (co se má stát)
* Nahrazuje *"tlusté"* **modely** a **controllery**
* Má jasný flow: **validace** → **logika** → **persistence**
* Vrací **Result objekt** (*success*/*failure*)

**Contract** = *Validace* dat
* Nahrazuje **strong_parameters** a **model validace**
* Používá **Reform** (*form objects*)

**Cell** = *View* komponenty
* Alternativa k partials (optional, nemusíš používat hned)

## 2. Instalace
```
# Gemfile
gem 'trailblazer-rails'
gem 'reform-rails'
```

```bash
bundle install
rails restart
```

## 3. Vytvoř Order::Create Operation
```ruby
# app/concepts/order/operation/create.rb
module Order::Operation
  class Create < Trailblazer::Operation
    # Krok 1: Nastav model
    step :model
    # Krok 2: Validuj vstup (contract)
    step :contract_build
    step :contract_validate
    # Krok 3: Business logika
    step :validate_cart
    step :build_order_from_cart
    # Krok 4: Ulož
    step :persist
    step :clear_cart

    # Inicializace modelu
    def model(ctx, **)
      ctx[:model] = Order.new
    end

    # Validace vstupu (prázdný contract, protože data bereme z cartu)
    def contract_build(ctx, **)
      ctx[:contract] = Order::Contract::Create.new(ctx[:model])
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params)
    end

    # Zkontroluj, že cart není prázdný
    def validate_cart(ctx, current_cart:, **)
      return false if current_cart.nil? || current_cart.line_items.empty?
      
      ctx[:cart] = current_cart
      true
    end

    # Přenes data z cartu do objednávky
    def build_order_from_cart(ctx, current_user:, cart:, **)
      order = ctx[:model]
      order.user = current_user
      order.total_price = cart.total_price
      order.status = "pending"

      cart.line_items.each do |line_item|
        order.line_items.build(
          product: line_item.product,
          quantity: line_item.quantity,
          price: line_item.price
        )
      end

      true
    end

    # Ulož objednávku
    def persist(ctx, **)
      ctx[:model].save
    end

    # Smaž košík po úspěšném uložení
    def clear_cart(ctx, cart:, **)
      cart.destroy!
      true
    end
  end
end
```

## 4. Contract (validace)
```ruby
# app/concepts/order/contract/create.rb
module Order::Contract
  class Create < Reform::Form
    property :user_id
    property :status
    property :total_price

    # Validace (pokud nějaké potřebuješ)
    validates :user_id, presence: true
    validates :status, inclusion: { in: %w[pending confirmed shipped delivered] }
  end
end
```

## 5. Refactor Controller
```ruby
# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  # POST /orders
  def create
    # Zavolej operaci místo model metody
    result = Order::Operation::Create.call(
      params: {},  # Prázdné, protože bereme z cartu
      current_cart: current_cart,
      current_user: current_user
    )

    if result.success?
      redirect_to result[:model], notice: "Objednávka byla úspěšně vytvořena."
    else
      redirect_to cart_path(current_cart), alert: "Košík je prázdný, objednávka nebyla vytvořena."
    end
  end
  
  # Zbytek akcí zatím ponech v MVC
  def index
    @orders = Order.all
  end

  def show
    @order = Order.find(params[:id])
  end

  # ...
end
```

## 6. Co se změnilo?

### PŘED (MVC):
```
Controller → Model.create_from_cart → Database
                 ↓
    Tlusté modely, logika všude
```

### PO (Trailblazer):
```
Controller → Operation (kroky) → Database
              ↓
         Jasná cesta:
         1. Model setup
         2. Validace
         3. Business logika
         4. Persistence
         5. Cleanup
```

## 7. Výhody
✅ Testovatelnost - testuješ operaci, ne controller
✅ Jasný flow - vidíš všechny kroky
✅ Znovupoužitelnost - můžeš volat z API, CLI, jobů
✅ Oddělení zodpovědností - každý krok dělá jednu věc


## 8. Model po refactoru
```ruby
# app/models/order.rb
class Order < ApplicationRecord
  has_many :line_items, as: :buyable
  belongs_to :user

  # Smaž create_from_cart - logika je teď v operaci!
  # Model je jen "hloupý" datový objekt
end
```

## 9.Spustit
```bash
rails restart
```
