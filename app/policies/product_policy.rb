class ProductPolicy < ApplicationPolicy
  def index?
    true # Všichni vidí produkty
  end

  def show?
    true
  end

  def create?
    user.admin? || user.supplier?
  end

  def update?
    user.admin? || (user.supplier? && user_owns_brand?)
  end

  def destroy?
    user.admin? || (user.supplier? && user_owns_brand?)
  end

  private

  def user_owns_brand?
    return false unless record.brand_id
    user.brand_ids.include?(record.brand_id)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.supplier?
        scope.where(brand_id: user.brand_ids)
      else
        scope.all # Customers vidí všechny produkty
      end
    end
  end
end
