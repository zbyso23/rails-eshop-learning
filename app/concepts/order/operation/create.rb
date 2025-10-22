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
