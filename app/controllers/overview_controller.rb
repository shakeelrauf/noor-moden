class OverviewController < ApplicationController
  def index
  	@orders = Order.all
  	@start_date = Date.strptime(params[:startDate], "%m/%d/%Y") rescue nil
  	@end_date = Date.strptime(params[:endDate], "%m/%d/%Y") rescue nil
  	@payment = params[:payment]
  	if @start_date and @end_date
  		@orders = @orders.where('created_at >= ? AND created_at <= ?',@start_date, @end_date)
  	end
  	@orders = @orders.where(paidtype: @payment) if @payment
  	@orders = @orders.order(created_at: :desc)
  end
end

