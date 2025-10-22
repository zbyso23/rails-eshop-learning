module Rating::Operation
  class Create < Trailblazer::Operation
    step :model
    step :contract_build
    step :contract_validate
    step :contract_sync
    step :assign_user
    step :persist

    def model(ctx, **)
      ctx[:model] = Rating.new
    end

    def contract_build(ctx, **)
      ctx[:contract] = Rating::Contract::Create.new(ctx[:model])
    end

    def contract_validate(ctx, params:, **)
      ctx[:contract].validate(params[:rating])
    end

    def contract_sync(ctx, **)
      ctx[:contract].sync
      true
    end

    def assign_user(ctx, current_user:, **)
      ctx[:model].user = current_user
      true
    end

    def persist(ctx, **)
      ctx[:model].save
    end
  end
end
