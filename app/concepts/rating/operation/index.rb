module Rating::Operation
  class Index < Trailblazer::Operation
    step :fetch_ratings
    step :apply_filters
    step :apply_sorting
    step :paginate
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

    def apply_filters(ctx, params:, **)
      query = ctx[:model]

      # Filtr podle product_id
      query = query.where(product_id: params[:product_id]) if params[:product_id].present?

      # Filtr podle user_id
      query = query.where(user_id: params[:user_id]) if params[:user_id].present?

      # Filtr podle min/max hodnoty
      query = query.where("value >= ?", params[:min_rating]) if params[:min_rating].present?
      query = query.where("value <= ?", params[:max_rating]) if params[:max_rating].present?

      # Filtr podle data
      query = query.where("created_at >= ?", params[:from_date]) if params[:from_date].present?
      query = query.where("created_at <= ?", params[:to_date]) if params[:to_date].present?

      ctx[:model] = query
      true
    end

    def apply_sorting(ctx, params:, **)
      sort_by = params[:sort_by] || "created_at"
      direction = params[:direction] || "desc"

      # Whitelist povolených sloupců
      allowed_columns = %w[value created_at product_id user_id]
      sort_by = "created_at" unless allowed_columns.include?(sort_by)

      direction = "desc" unless %w[asc desc].include?(direction)

      ctx[:model] = ctx[:model].order("ratings.#{sort_by} #{direction}")
      true
    end

    def paginate(ctx, params:, **)
      page = params[:page] || 1
      per_page = params[:per_page] || 25

      # Limit per_page na max 100
      per_page = [ per_page.to_i, 100 ].min

      ctx[:model] = ctx[:model].page(page).per(per_page)
      ctx[:pagination] = {
        current_page: ctx[:model].current_page,
        total_pages: ctx[:model].total_pages,
        total_count: ctx[:model].total_count,
        per_page: per_page.to_i
      }
      true
    end

    def include_associations(ctx, **)
      # Eager loading pro výkon
      ctx[:model] = ctx[:model].includes(:product, :user)
      true
    end
  end
end
