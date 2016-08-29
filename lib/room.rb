class Room
	attr_accessor :header, :title, :first_time_message, :description, :details, :items, :rooms, :access_points
	attr_writer :starting_location

	def has_room_to_the?(direction)
		rooms.key?(direction)
	end

	def starting_location?
		@starting_location
	end
end
