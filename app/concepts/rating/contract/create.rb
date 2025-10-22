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
