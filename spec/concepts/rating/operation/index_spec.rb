require "rails_helper"

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

  describe "bez filtrů" do
    it "vrátí všechna hodnocení" do
      result = described_class.call(params: {})

      expect(result.success?).to be true
      expect(result[:model].count).to eq(3)
    end
  end

  describe "filtr podle product_id" do
    it "vrátí jen hodnocení daného produktu" do
      result = described_class.call(params: { product_id: product.id })

      expect(result.success?).to be true
      expect(result[:model].count).to eq(3)
      expect(result[:model].pluck(:product_id).uniq).to eq([ product.id ])
    end
  end

  describe "filtr podle min_rating" do
    it "vrátí jen hodnocení >= 4" do
      result = described_class.call(params: { min_rating: 4 })

      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
      expect(result[:model].pluck(:value)).to match_array([ 4, 5 ])
    end
  end

  describe "filtr podle max_rating" do
    it "vrátí jen hodnocení <= 3" do
      result = described_class.call(params: { max_rating: 3 })

      expect(result.success?).to be true
      expect(result[:model].count).to eq(1)
      expect(result[:model].first.value).to eq(3)
    end
  end

  describe "filtr podle data" do
    it "vrátí jen hodnocení od včerejška" do
      result = described_class.call(params: { from_date: 1.day.ago.beginning_of_day })

      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
    end
  end

  describe "řazení" do
    it "seřadí podle value vzestupně" do
      result = described_class.call(params: { sort_by: "value", direction: "asc" })

      expect(result.success?).to be true
      expect(result[:model].pluck(:value)).to eq([ 3, 4, 5 ])
    end
  end

  describe "stránkování" do
    it "vrátí první stránku s 2 položkami" do
      result = described_class.call(params: { page: 1, per_page: 2 })

      expect(result.success?).to be true
      expect(result[:model].count).to eq(2)
      expect(result[:pagination][:current_page]).to eq(1)
      expect(result[:pagination][:total_pages]).to eq(2)
      expect(result[:pagination][:total_count]).to eq(3)
    end
  end
end
