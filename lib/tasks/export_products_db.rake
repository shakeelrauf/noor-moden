namespace :export_products_db do
  desc "to export products to csv"
  task to_csv: :environment do
  	require 'csv' 
  	current = DateTime.now
	file = "#{ENV['EXPORT_STORAGE_PATH']}/#{current.strftime('%d-%m-%Y-%H:%M:%S')}.csv"
	products = Product.where(sync_with_modiprofi: true)
	headers = ["ORDERNR", "DATUM", "KUNDENNR", "FIRMA", "ANREDE","VORNAME", "NACHNAME", "STRASSE", "PLZ", "ORT", "ZAHLUNGSART", "GESAMTBETRAG","AUFTRAGSART", "VORFRACHT", "VERSAND", "PORTO", "SKONTO","MWST", "BEMERKUNG", "TELEFON", "FAX", "MOBIL", "LAND","MAIL", "PS", "ARTIEKLNR", "ARTIKELNAME","FARBE", "GR", "MENGE", "VK","RABATT", "GESAMTVK", "INVENTORY COUNT"]

	CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
	  products.each do |product| 
	  	array = ['','','','','','','','','','','','','Inventory','','','','','','','','','','','','',product.model_number,'', '', '', '','','','',product.inventory]
	  	writer << array 
	  end
	end
  end

end
