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
  def create
    product = Product.find(params[:product_id])
    @line_item = @current_cart.add_product(product, params[:quantity])

    if @line_item.save
      redirect_to cart_path(@current_cart), notice: "Product added to cart."
    else
      redirect_to product_path(product), alert: "Cannot add Product to cart."
    end
  end

  # PATCH/PUT /line_items/1 or /line_items/1.json
  def update
    @line_item = current_cart.line_items.find(params[:id])
    if @line_item.update(line_item_params)
      redirect_to cart_path(current_cart), notice: "Množství bylo aktualizováno."
    else
      redirect_to cart_path(current_cart), alert: "Chyba při aktualizaci."
    end
  end

  # DELETE /line_items/1 or /line_items/1.json
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

    def line_item_params
      params.require(:line_item).permit(:quantity)
    end
end
