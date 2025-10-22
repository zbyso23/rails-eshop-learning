json.extract! line_item, :id, :product_id, :quantity, :price, :buyable_id, :buyable_type, :created_at, :updated_at
json.url line_item_url(line_item, format: :json)
