class Tax < ApplicationRecord
	validates :percentage, numericality: { less_than_or_equal_to: 100}
end
