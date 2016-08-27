class Player
	attr_accessor :x_coord, :y_coord

	MAX_HIT_POINTS = 100

	def initialize
		@hit_points        = MAX_HIT_POINTS
		@attack_power      = 1
		@x_coord, @y_coord = 0, 0 
	end


end
