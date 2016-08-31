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

	def input_movement(command, entered_words)
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

	def look(input, command, command_two)
		if input == "look closer"
			@current_message = avatar.location.details["phrase"]
			# this is where you'll need to check if knowledge == true for a room details, and if so add it to the avatar's knowledge array
		elsif command == "look" && command_two != "closer" && !command_two.nil?
			@current_message = "Sorry, I only understand you as far as wanting to look."
		else
			@current_message = avatar.location.description
		end
	end

	def pick_up_item(object)
		inventory_checker = avatar.items.find do |item|
			item.has_value?(object)
		end

		if inventory_checker != nil && inventory_checker["handle"] == object
			@current_message = "You're already holding that!"
			return
		end

		room_checker = avatar.location.items.find do |item|
			item.has_value?(object)
		end

		if room_checker != nil
			avatar.location.items.each do |item|
				if room_checker["handle"] == object
					avatar.items << item
					avatar.location.items.delete(item)
					@current_message = "You've picked up the #{object}"
				end
			end
		else
			@current_message = "Sorry, that doesn't appear to be here."
		end
	end

	def drop_item(object)
		inventory_checker = avatar.items.find do |item|
			item.has_value?(object)
		end

		if inventory_checker != nil && inventory_checker["handle"] == object			
			avatar.items.each do |item|
				if inventory_checker["handle"] == object
					avatar.items.delete(item)
					avatar.location.items << item
				end
			end
			@current_message = "You have dropped the #{object}"
		else
			@current_message = "Ummm I don't think you're carrying that, dude"
		end
	end

	def view_inventory
		if avatar.items.size != 0
			@current_message = "This is where it should say what you're holding"
		else
			@current_message = "You are not currently carrying anything"
		end
	end

	def evaluate(input)
		input.downcase!
		entered_words = input.split

		unless valid?(input)
			@current_message = "Sorry, that is not a valid command."
			return
		end		

		command = entered_words[0]
		command_two = entered_words[1]
		command_three = entered_words[2]
		command_four = entered_words[3]

		if command == "go"
			input_movement(command, entered_words)
		end

		if command == "look"
			look(input, command, command_two)
		end
		
		if command == "take"
			pick_up_item(command_two)
		end

		if command == "drop"
			drop_item(command_two)
		end

		if input == "inventory" || input == "i"
			view_inventory
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
		if valid_commands.include?(entered_words.first) && entered_words.size >= 1
			result = true
		end
		result
	end

	def valid_commands
		# only needs to pass the first word or letter of the command to be considered valid
		@commands ||= %w(go look exit quit help h inventory i take drop)
	end
end
