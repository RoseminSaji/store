class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :destroy]

  def index
    @products = Product.order(:name)
    render json: @products, status: :ok
  end

  def show
    render json: @product, status: :ok
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      render json: @product, status: :created
    else
      render_validation_error(@product)
    end
  end

  def update
    if @product.update(product_params)
      render json: @product, status: :ok
    else
      render_validation_error(@product)
    end
  end

  def destroy
    @product.destroy
    head :no_content
  end

  private

  def product_params
    params.require(:product).permit(
      :name, :product_code, :stock, :unit_price, :tax_percentage
    )
  end 

  def set_product
    @product = Product.find(params[:id])
  end
end