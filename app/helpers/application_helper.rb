module ApplicationHelper

	def has_file? order_id
		@file = "#{ENV['EXPORT_STORAGE_PATH']}/orders/#{order_id}.csv"
		File.exist?(@file) 
	end
end
