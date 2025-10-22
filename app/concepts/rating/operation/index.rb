module Rating::Operation
  class Index < Trailblazer::Operation
    step :fetch_ratings
    step :include_associations

    def fetch_ratings(ctx, params:, **)
      # Volitelný filtr podle product_id
      if params[:product_id].present?
        ctx[:model] = Rating.where(product_id: params[:product_id])
      else
        ctx[:model] = Rating.all
      end
      true
    end

    def include_associations(ctx, **)
      # Eager loading pro výkon
      ctx[:model] = ctx[:model].includes(:product, :user)
      true
    end
  end
end
