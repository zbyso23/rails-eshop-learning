class RatingsController < ApplicationController
  before_action :set_rating, only: %i[ show edit update destroy ]

  # GET /ratings or /ratings.json
  def index
    @ratings = Rating.all
  end

  # GET /ratings/1 or /ratings/1.json
  def show
  end

  # GET /ratings/new
  def new
    @rating = Rating.new
  end

  # GET /ratings/1/edit
  def edit
  end

  # POST /ratings or /ratings.json [w/o]
  # def create
  #   @rating = Rating.new(rating_params)

  #   respond_to do |format|
  #     if @rating.save
  #       format.html { redirect_to @rating, notice: "Rating was successfully created." }
  #       format.json { render :show, status: :created, location: @rating }
  #     else
  #       format.html { render :new, status: :unprocessable_entity }
  #       format.json { render json: @rating.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # POST /ratings
  def create
    result = Rating::Operation::Create.call(
      params: params.to_unsafe_h,
      current_user: current_user
    )
    puts "=== RESULT ==="
    puts "Success: #{result.success?}"
    puts "Contract: #{result[:contract].inspect}"
    puts "Model: #{result[:model].inspect}"
    puts "Errors: #{result['contract.default']&.errors&.full_messages}"
    puts "=============="
    respond_to do |format|
      if result.success?
        @rating = result[:model]
        format.html { redirect_to product_path(@rating.product), notice: "Hodnocení bylo přidáno." }
        format.json { render :show, status: :created, location: @rating }
      else

        format.html {
          @product = Product.find(params[:rating][:product_id])
          render "products/show", status: :unprocessable_entity
        }
        format.json { render json: result[:contract].errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ratings/1 or /ratings/1.json
  def update
    respond_to do |format|
      if @rating.update(rating_params)
        format.html { redirect_to @rating, notice: "Rating was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @rating }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rating.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ratings/1 or /ratings/1.json
  def destroy
    @rating.destroy!

    respond_to do |format|
      format.html { redirect_to ratings_path, notice: "Rating was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rating
      @rating = Rating.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def rating_params
      params.expect(rating: [ :value, :product_id, :user_id ])
    end
end
