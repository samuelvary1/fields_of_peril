require 'readline'

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

		if avatar.location.title == "apartment_living_room"
			avatar.location.been_before = true
		end
	end

	def input_movement(command, entered_words)
		entered_words = [entered_words[0], entered_words[1]]
		direction = entered_words.last
		case direction 
			when "n"
				direction = "north"
			when "s"
				direction = "south"
			when "e"
				direction = "east"
			when "w"
				direction = "west"
			when "d"
				direction = "down"
			when "u"
				direction = "up"
		end

		if avatar.location.access_points && avatar.location.access_points[direction] && avatar.location.access_points[direction]["locked"]
			if !avatar.location.access_points[direction]["visible"]
				@current_message = "Sorry, you cannot go #{direction} from here."
				return
			end
			@current_message = "Sorry, that #{avatar.location.access_points[direction]["game_handle_display"]} seems to be locked."
			return
		end

		if avatar.can_move?(direction)

			new_room = avatar.location.rooms[direction]
		
			if new_room.been_before
				avatar.move(direction)
				@current_message = avatar.location.header
			end

			if !new_room.been_before
				avatar.move(direction)
				@current_message = avatar.location.first_time_message
				new_room.been_before = true
			end

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

	def take_item(object)

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

		room_container_checker = avatar.location.items.select do |item|
			item["container"] && item["contents"] && item["open"]
		end

		inventory_container_checker = avatar.items.select do |item|
			item["container"] && item["contents"] && item["open"]
		end

		if inventory_container_checker.size == 0 && room_container_checker.size > 0 
			correct_container = room_container_checker.find do |item|
				item["contents"].find do |content|
					content.has_value?(object)
				end
			end
		elsif inventory_container_checker.size > 0 && room_container_checker.size == 0 
			correct_container = inventory_container_checker.find do |item|
				item["contents"].find do |content|
					content.has_value?(object)
				end
			end
		end

		if !correct_container.nil?
			selected_object = correct_container["contents"].find do |item|
				item.has_value?(object)
			end
			avatar.items.insert(0, selected_object)
			correct_container["contents"].delete(selected_object)
			@current_message = "You've picked up the #{object}"
			return
			elsif room_checker != nil		
			  if room_checker["mobile"] == false
			  	@current_message = "It won't budge"
			  	return
		  	end	
				avatar.location.items.each do |item|
					if item["handle"] == object
						avatar.items.insert(0, item)
						avatar.location.items.delete(item)
						@current_message = "You've picked up the #{object}"
					end
				end
		else
			@current_message = "Sorry, that doesn't appear to be here."
		end
	end

	def put_in_container(object, container)

		inventory_checker = avatar.items.find do |item|
			item.has_value?(object)
		end

		room_container_checker = avatar.location.items.select do |item|
			item["container"] && item["open"]
		end

		inventory_container_checker = avatar.items.select do |item|
			item["container"] && item["open"]
		end

		if inventory_checker.nil?
			@current_message = "I don't think you're carrying that"
			return
		end

		if room_container_checker.size > 0 && inventory_container_checker.size == 0
			correct_container = room_container_checker.find do |item|
				item.has_value?(container)
			end
			elsif inventory_container_checker.size > 0 && room_container_checker.size == 0
				correct_container = inventory_container_checker.find do |item|
					item.has_value?(container)
				end
		end

		# binding.pry

		if correct_container.nil?
			@current_message = "There are no open containers like that here"
			return
		else
			avatar.items.each do |item|
				if item["handle"] == object
					avatar.items.delete(item)
					correct_container["contents"].insert(0, item)
				end
			end
		end

		@current_message = "You have placed the #{object} in the #{container}"

	end

	def drop_item(object)
		inventory_checker = avatar.items.find do |item|
			item.has_value?(object)
		end

		if inventory_checker != nil && inventory_checker["handle"] == object			
			avatar.items.each do |item|
				if item["handle"] == object
					avatar.items.delete(item)
					avatar.location.items.insert(0, item)
				end
			end
			@current_message = "You have dropped the #{object}"
		else
			@current_message = "Ummm I don't think you're carrying that, dude"
		end
	end

	def read_item(object)
		inventory_checker = avatar.items.find do |item|
			item.has_value?(object)
		end

		room_checker = avatar.location.items.find do |item|
			item.has_value?(object)
		end

		if inventory_checker != nil && inventory_checker["handle"] == object && inventory_checker["letter"] 
			@current_message = inventory_checker["details"]["phrase"]
			elsif room_checker != nil && room_checker["handle"] == object && room_checker["letter"]
				@current_message = room_checker["details"]["phrase"]
		else
			@current_message = "I don't see anything like that to read here."
		end
	end

	def use_keypad
		keypad = avatar.location.items.find do |item|
			item.has_value?("keypad")
		end

		if avatar.location.access_points[keypad["location"]]["locked"] == false
			@current_message = "you've already successfully authorized with this keypad, ya big dummy."
			return
		end

		if keypad != nil && keypad["handle"] == "keypad" 
			puts "your fingers hover over the keypad. what's the code, champ?"
			input = Readline.readline('CODE:', true)

			if input.to_i != 0
				attempt = input.to_i

				if attempt == keypad["code"]
					@current_message = "that worked! you've unlocked the access point."
					avatar.location.access_points[keypad["location"]]["locked"] = false
				else
					@current_message = "i'm sorry, that's incorrect."
				end
			end
		else
			@current_message = "I'm sorry, i don't see a keypad anywhere around here."
		end			
	end

	def unlock_access_point(input, command, command_two, command_three, command_four, command_five)
		avatar.location.access_points.each do |direction, access_point|
			if access_point && access_point["game_handle"] == command_two && access_point["locked"]
				if input == "unlock #{command_two}" && command_three.nil? || command_four.nil?
					@current_message = "What do you want to unlock the #{command_two} with?"
					return
				end
			end

			if access_point["game_handle"] && access_point["game_handle"] == command_two && access_point["locked"] && command_three == "with" && !command_four.nil?
				key = avatar.items.find do |item|
					item["handle"] == command_four
				end

				if key.nil?
					@current_message = "I don't think you're carrying that"
					return
				elsif key["code"] == access_point["code"]
					access_point["locked"] = false
					@current_message = "It fits! you've unlocked the #{access_point["game_handle_display"]}"
					return
				else
					@current_message = "shoot, that's not the right key"
					return
				end

			elsif access_point["game_handle"] == command_two && !access_point["locked"]
				@current_message = "That already appears to be unlocked."
			else
				@current_message = "I don't think you can unlock anything like that here."
			end
		end
	end

	def view_inventory
		if avatar.items.size != 0
			@current_message = avatar.list_items
		else
			@current_message = "You are not currently carrying anything"
		end
	end

	def look_at(object)
		check_inventory = avatar.items.find do |item|
			item.has_value?(object)
		end

		check_room = avatar.location.items.find do |item|
			item.has_value?(object)
		end

		if check_inventory.nil? && check_room.nil?
			@current_message = "I don't think you can look at anything like that here."
		end

		if check_inventory
			@current_message = check_inventory["description"]
			# need to check if knowledge is true and if so add it to a knowledge inventory.. if you decide to implement that system.
		end

		if check_room
			@current_message = check_room["description"]
		end			 
	end

	def look_in(object)
		check_inventory = avatar.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		check_room = avatar.location.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		if check_inventory.nil? && check_room.nil?
			@current_message = "I don't think you can look inside anything like that here"
			return
		end

		if check_room.nil? && !check_inventory.nil?
			if check_inventory["open"] || check_inventory["transparent"]
				@current_message = "Inside the #{check_inventory["handle"]} you see #{check_inventory["contents"]}."
			elsif !check_inventory["open"] && !check_inventory["transparent"]
				@current_message = "That's closed and/or not transparent, you can't see inside it."
			end
		else
			if check_room["open"] || check_room["transparent"]
				@current_message = "Inside the #{check_room["handle"]} you see a #{check_room["contents"]}"
			elsif !check_room["open"] && !check_room["transparent"]
				@current_message = "That's closed and/or not transparent, you can't see inside it."
			end
		end
	end

	def open(object)
		room_container = avatar.location.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		carried_container = avatar.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		if room_container.nil? && carried_container.nil?
			@current_message = "I don't see anything like that to open in here."
		end

		if room_container.nil? && !carried_container.nil?
			if carried_container["locked"]
				@current_message = "That seems to be locked"
			elsif carried_container["open"]
				@current_message = "That's already open"
			else
				@current_message = "You've opened the #{carried_container["handle"]}"
				carried_container["open"] = true
			end
		elsif carried_container.nil? && !room_container.nil?
			if room_container["locked"]
				@current_message = "That seems to be locked"
			elsif room_container["open"]
				@current_message = "That's already open."
			else
				@current_message = "You've opened the #{room_container["handle"]}"
				room_container["open"] = true
			end
		end
	end

	def close(object)
		room_container = avatar.location.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		carried_container = avatar.items.find do |item|
			item.has_value?(object) && item["container"]
		end

		if room_container.nil? && carried_container.nil?
			@current_message = "I don't see anything like that to close in here."
		end

		if room_container.nil? && !carried_container.nil?
			if !carried_container["open"]
				@current_message = "That seems to be already closed"
			else
				@current_message = "You've closed the #{carried_container["handle"]}"
				carried_container["open"] = false
			end
		elsif carried_container.nil? && !room_container.nil?
			if !room_container["open"]
				@current_message = "That seems to be already closed"
			else
				@current_message = "You've closed the #{room_container["handle"]}"
				room_container["open"] = false
			end
		end
	end

	def evaluate(input)
		input.downcase!
		entered_words = input.split

		unless valid?(input)
			@current_message = "Sorry, that is not a valid command."
			return
		end		

		command       = entered_words[0]
		command_two   = entered_words[1]
		command_three = entered_words[2]
		command_four  = entered_words[3]
		command_five  = entered_words[4]

		if command == "go"
			if valid_directions.include?(entered_words[1])
				input_movement(command, entered_words)
			else
				@current_message = "Sorry, that doesn't seem to be a valid direction.."
			end
		end

		if "#{command} #{command_two}" == "look at"
			# this will break if you haven't added a details phrase to the item. you could make a default if there isn't much else to see, or you have to write a details phrase for every item in the game, whether there's anything to see or not. might add more layers to the game if you don't rely on a default.
			look_at(command_three)
		end

		if "#{command} #{command_two}" == "look in"
			look_in(command_three)
		end

		if command == "look" && command_two != "at" && command_two != "in"
			look(input, command, command_two)
		end

		if command == "open"
			open(command_two)
		end

		if command == "put" && command_three == "in"
			put_in_container(command_two, command_four)
		end

		if command == "close"
			close(command_two)
		end
		
		if command == "take"
			take_item(command_two)
		end

		if command == "drop"
			drop_item(command_two)
		end

		if input == "use keypad"
			use_keypad
		end

		if command == "read"
			read_item(command_two)
		end

		if command == "unlock"
			unlock_access_point(input, command, command_two, command_three, command_four, command_five)
		end

		if command == "inventory" || command == "i"
			view_inventory
		end

		if command == "help" || command == "h"
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
		@commands ||= %w(go look exit quit help h inventory i take drop unlock push pull use shoot open close put read)
	end

	def valid_directions
		@valid_directions ||= %(up down north south east west)
	end
end
