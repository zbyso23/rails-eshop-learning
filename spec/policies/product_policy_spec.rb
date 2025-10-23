require 'rails_helper'

RSpec.describe ProductPolicy do
  subject { described_class }

  let(:admin) { create(:user, role: 'admin') }
  let(:customer) { create(:user, role: 'customer') }
  let(:supplier) { create(:user, role: 'supplier') }
  let(:brand) { create(:brand) }
  let(:product) { create(:product, brand: brand) }

  before do
    supplier.brands << brand
  end

  permissions :create? do
    it "povolí adminovi" do
      expect(subject).to permit(admin, Product.new)
    end

    it "povolí supplierovi" do
      expect(subject).to permit(supplier, Product.new)
    end

    it "zakáže customerovi" do
      expect(subject).not_to permit(customer, Product.new)
    end
  end

  permissions :update?, :destroy? do
    it "povolí adminovi" do
      expect(subject).to permit(admin, product)
    end

    it "povolí supplierovi vlastní značky" do
      expect(subject).to permit(supplier, product)
    end

    it "zakáže supplierovi cizí značky" do
      other_product = create(:product, brand: create(:brand))
      expect(subject).not_to permit(supplier, other_product)
    end

    it "zakáže customerovi" do
      expect(subject).not_to permit(customer, product)
    end
  end
end
