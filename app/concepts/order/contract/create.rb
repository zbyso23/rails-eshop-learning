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
