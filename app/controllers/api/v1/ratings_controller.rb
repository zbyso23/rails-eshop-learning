module Api
  module V1
    class RatingsController < ApplicationController
      # GET /api/v1/ratings
      def index
        result = Rating::Operation::Index.call(
          params: params.to_unsafe_h
        )

        if result.success?
          render json: {
            success: true,
            data: result[:model].as_json(
              only: [ :id, :value, :product_id, :user_id, :created_at ],
              include: {
                product: { only: [ :id, :name ] },
                user: { only: [ :id, :email ] }
              }
            ),
            pagination: result[:pagination]
          }
        else
          render json: { success: false, errors: "Failed to fetch ratings" }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/ratings/category_averages
      def category_averages
        result = Rating::Operation::CategoryAverages.call(params: {})

        if result.success?
          render json: {
            success: true,
            data: result[:model]
          }
        else
          render json: { success: false, errors: "Failed to calculate averages" }, status: :unprocessable_entity
        end
      end
    end
  end
end
