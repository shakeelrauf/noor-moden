class HooksController < ApplicationController

  skip_before_action :authenticate_user!

	def get_hook
		require 'barby/barcode/code_128'
    require 'barby/outputter/ascii_outputter'
    require 'barby/outputter/png_outputter'
    require 'barby/outputter/svg_outputter'

    @imgs = Barby::Code128.new('123456789').to_image.to_data_url
    @png = Barby::Code128.new('Hello Universe').to_png
    @svg = Barby::Code128.new('123456789').to_svg(margin: 0)
    @svg = @svg.sub!('<svg ', '<svg preserveAspectRatio="none" ')


    # send_data( data, :filename => "my_file" )
   
	end

end