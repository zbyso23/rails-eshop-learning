require "rails_helper"

RSpec.describe Rating::Operation::CategoryAverages do
  let(:user) { create(:user) }
  let(:category1) { create(:category, name: "Elektronika") }
  let(:category2) { create(:category, name: "Oblečení") }
  let(:product1) { create(:product, category: category1) }
  let(:product2) { create(:product, category: category2) }

  before do
    create(:rating, product: product1, value: 5)
    create(:rating, product: product1, value: 3)
    create(:rating, product: product2, value: 4)
  end

  it "vypočítá průměry per kategorie" do
    result = described_class.call(params: {})

    expect(result.success?).to be true
    expect(result[:model].count).to eq(2)

    elektronika = result[:model].find { |c| c[:category_name] == "Elektronika" }
    expect(elektronika[:average_rating]).to eq(4.0)
    expect(elektronika[:ratings_count]).to eq(2)

    obleceni = result[:model].find { |c| c[:category_name] == "Oblečení" }
    expect(obleceni[:average_rating]).to eq(4.0)
    expect(obleceni[:ratings_count]).to eq(1)
  end
end
