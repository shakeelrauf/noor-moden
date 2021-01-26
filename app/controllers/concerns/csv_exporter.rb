module CsvExporter
	require 'csv' 

	module InstanceMethods
		def export_order_to_csv data, order_id
		  @current = DateTime.now
			@file = "#{ENV['EXPORT_STORAGE_PATH']}/orders/#{order_id}.csv"
			@headers = ["ORDERNR", "DATUM", "KUNDENNR", "FIRMA", "ANREDE","VORNAME", "NACHNAME", "STRASSE", "PLZ", "ORT", "ZAHLUNGSART", "GESAMTBETRAG","AUFTRAGSART", "VORFRACHT", "VERSAND", "PORTO", "SKONTO","MWST", "BEMERKUNG", "TELEFON", "FAX", "MOBIL", "LAND","MAIL", "PS", "ARTIEKLNR", "ARTIKELNAME","FARBE", "GR", "MENGE", "VK","RABATT", "GESAMTVK"]
			CSV.open(@file, 'w', write_headers: true, headers: @headers) do |writer|
				data.each do |item|
					array = Array.new @headers.length, ''
					array[25] = item[:product]
	  			array[11] = item[:order_total_price]
	  			array[12] = item[:order_type]
	  			array[29] = item[:line_item_quantity]
	  			array[30] = item[:line_item_price]
	  			array[32] = item[:line_item_total_price]
	  			writer << array 
	  		end
	  	end
		end	
	end

	module ClassMethods
	end
		
	def self.included(receiver)
		receiver.extend         ClassMethods
		receiver.send :include, InstanceMethods
	end
end