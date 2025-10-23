# Cleanup - v OPAČNÉM pořadí závislostí!
puts "🧹 Mazání starých dat..."

Rating.destroy_all
Comment.destroy_all
LineItem.destroy_all
Order.destroy_all
Cart.destroy_all
Product.destroy_all
BrandsUser.destroy_all
Brand.destroy_all
Category.destroy_all
User.destroy_all

puts "✅ Stará data smazána"

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
