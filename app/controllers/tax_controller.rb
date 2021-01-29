class TaxController < ApplicationController
  before_action :set_tax

  def index
  end

  def update
    @tax.update(tax_params)
    redirect_to tax_index_url,  notice: 'Tax Updated.'
  end

  private
    def set_tax
      @tax = Tax.first || Tax.create
    end

    def tax_params
      params.require(:tax).permit(:percentage)
    end
end

