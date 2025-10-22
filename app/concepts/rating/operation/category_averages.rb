module Rating::Operation
  class CategoryAverages < Trailblazer::Operation
    step :fetch_data
    step :calculate_averages

    def fetch_data(ctx, **)
      # SQL agregace - efektivní!
      ctx[:raw_data] = Rating
        .joins(product: :category)
        .group("categories.id", "categories.name")
        .select(
          "categories.id as category_id",
          "categories.name as category_name",
          "AVG(ratings.value) as average_rating",
          "COUNT(ratings.id) as ratings_count"
        )
      true
    end

    def calculate_averages(ctx, **)
      # Transformuj data do čitelného formátu
      ctx[:model] = ctx[:raw_data].map do |record|
        {
          category_id: record.category_id,
          category_name: record.category_name,
          average_rating: record.average_rating.to_f.round(2),
          ratings_count: record.ratings_count
        }
      end
      true
    end
  end
end
