class LineItemsController < ApplicationController
  before_action :set_line_item, only: %i[ show edit update destroy ]

  # GET /line_items or /line_items.json
  def index
    @line_items = LineItem.all
  end

  # GET /line_items/1 or /line_items/1.json
  def show
  end

  # GET /line_items/new
  def new
    @line_item = LineItem.new
  end

  # GET /line_items/1/edit
  def edit
  end

  # POST /line_items or /line_items.json
  # def create
  #   @line_item = LineItem.new(line_item_params)

  #   respond_to do |format|
  #     if @line_item.save
  #       format.html { redirect_to @line_item, notice: "Line item was successfully created." }
  #       format.json { render :show, status: :created, location: @line_item }
  #     else
  #       format.html { render :new, status: :unprocessable_entity }
  #       format.json { render json: @line_item.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  def create
    product = Product.find(params[:product_id])
    @line_item = current_cart.add_product(product, params[:quantity])

    if @line_item.save
      redirect_to cart_path(current_cart), notice: "Product added to cart."
    else
      redirect_to product_path(product), alert: "Cannot add Product to cart."
    end
  end

  # PATCH/PUT /line_items/1 or /line_items/1.json
  # def update
  #   respond_to do |format|
  #     if @line_item.update(line_item_params)
  #       format.html { redirect_to @line_item, notice: "Line item was successfully updated.", status: :see_other }
  #       format.json { render :show, status: :ok, location: @line_item }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @line_item.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end
  def update
    @line_item = current_cart.line_items.find(params[:id])
    if @line_item.update(line_item_params)
      redirect_to cart_path(current_cart), notice: "Množství bylo aktualizováno."
    else
      redirect_to cart_path(current_cart), alert: "Chyba při aktualizaci."
    end
  end

  # DELETE /line_items/1 or /line_items/1.json
  # def destroy
  #   @line_item.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to line_items_path, notice: "Line item was successfully destroyed.", status: :see_other }
  #     format.json { head :no_content }
  #   end
  # end
  def destroy
    @line_item = current_cart.line_items.find(params[:id])
    @line_item.destroy
    redirect_to cart_path(current_cart), notice: "Položka byla odstraněna."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line_item
      @line_item = LineItem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    # def line_item_params
    #   params.expect(line_item: [ :product_id, :quantity, :price, :buyable_id, :buyable_type ])
    # end
    def line_item_params
      params.require(:line_item).permit(:quantity)
    end
end
