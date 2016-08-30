class InputController
	attr_reader :avatar, :current_message
	
	def avatar=(avatar)
		@avatar = avatar
	end

	def messages=(messages)
		@messages = messages
	end

	def initialize_message
		@current_message = "#{avatar.location.header}\n #{avatar.location.first_time_message}"	
	end

	def check_movement(command, entered_words)
		
			direction = entered_words.last
			if avatar.can_move?(direction)
				avatar.move(direction)
				# this is where we need a way to check if the player has ever been in the room before. if true, first_time_message, else, basic description
				# currently with this setup you obviously get the first_time_message every time you go into a room, no matter how many times you've been there.
				# the first_time_message is important because there should be things that are triggered (such as ambushes etc.) the first time you get somewhere
				# it will also be key because if that first_time action is triggered and you don't have a certain item, you'll get killed. 
				# that is an important part of the overall gameplay.
				@current_message = avatar.location.first_time_message
			else
				@current_message = "Sorry, you cannot go #{direction} from here."
			end
	end

	def check_looking(input)
		if input == "look"
			@current_message = avatar.location.description
		elsif 
			input == "look carefully" || input == "look closer"
			@current_message = avatar.location.details["phrase"]
			# this is where you'll need to check if knowledge == true for a room details, and if so add it to the avatar's knowledge array
		elsif input.include?("look")
			@current_message = "Sorry, I only understand you as far as wanting to look."
		end
	end

	def check_pickup_item(object)
		checker = avatar.items.find do |item_hash|
			item_hash.has_value?(object)
		end

		if !checker.nil? && checker["handle"] == object
			# binding.pry
			@current_message = "You're already holding that!"
			@toggle = false
		end

		if @toggle
			avatar.location.items.each do |item|
				if item.has_value?("#{object}")
					avatar.items << item
					avatar.location.items.delete(item)
					@current_message = "You've picked up the #{object}"
				else
					@current_message = "Sorry, that doesn't appear to be here."
				end
			end
		end
	end

	def check_inventory
		if avatar.items.size != 0
			@current_message = avatar.list_items
		else
			@current_message = "You are not currently carrying anything"
		end
	end

	def evaluate(input)
		@toggle = false
		input.downcase!
		entered_words = input.split

		unless valid?(input)
			@current_message = "Sorry, that is not a valid command."
			return
		end		

		command = entered_words[0]
		command_two = entered_words[1]


		check_looking(input)
		
		if input == "inventory" || input == "i"
			check_inventory
		end

		if command == "go"
			check_movement(command, entered_words)
		end

		if command == "take"
			@toggle = true
			check_pickup_item(command_two)
		end

		if input == "help" || input == "h"
			@current_message = @messages["help"]
		end

		if command == "exit" || command == "quit"
			puts "Thank you for playing!"
			exit(0)
		end
	end

	def valid?(input)
		entered_words = input.split
		result = false
		if valid_commands.include?(entered_words.first) && entered_words.size == 1
			result = true
		elsif entered_words.size >= 2 
			result = true
		end
		result
	end

	def valid_commands
		# only needs to pass the first word or letter of the command to be considered valid
		@commands ||= %w(look exit quit help h inventory i take)
	end
end
