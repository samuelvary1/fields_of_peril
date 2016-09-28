class Item
	attr_accessor :handle, :alt_handle, :description, :inside, :details, :letter, :direction, :code, :location, :container, :open, :transparent, :mobile, :locked, :contents

	def list_contents
		puts "You peer inside the #{handle} and see: "
		puts ""
		
		contents.collect do |item|
			item.description
		end
	end

end