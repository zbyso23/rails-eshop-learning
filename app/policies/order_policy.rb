class OrderPolicy < ApplicationPolicy
  def index?
    true # Každý vidí objednávky (filtrované v scope)
  end

  def show?
    user.admin? || record.user_id == user.id
  end

  def create?
    true # Každý může vytvořit objednávku
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
