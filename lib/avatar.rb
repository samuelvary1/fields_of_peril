class Avatar
	attr_accessor :items, :knowledge, :score
	def initialize(starting_location)
		@current_room = starting_location
		@items = []
		@knowledge = []
		@score = 0
	end

	def location
		@current_room
	end

	def can_move?(direction)
		# valid directions (depending on the room) are up, down, north, south, east, and west
		@current_room.has_room_to_the?(direction)
	end

	def move(direction)
		if can_move?(direction)
			new_room = @current_room.rooms[direction]
			@current_room = new_room
			true
		else
			false
		end
	end
end
