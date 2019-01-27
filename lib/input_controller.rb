require 'readline'
require 'pry'

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

	def input_movement(direction)

		if direction == "north" || direction == "n"
			direction = "north" 
		elsif direction == "south" || direction == "s"
			direction = "south"
		elsif direction == "east" || direction == "e"
			direction = "east"
		elsif direction == "west" || direction == "w"
			direction = "west"
		elsif direction == "up" || direction == "u"
			direction = "up"
		elsif direction == "down" || direction == "d"
			direction = "down"
		else
			@current_message = "Sorry, that doesn't seem to be a valid direction"
			return
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

	# begin look commands

	def look(input)
		
		look_phrase = input.split(" ")

		if look_phrase[1] == "at" || look_phrase[2] == "at" || look_phrase[0] == "examine"
			look_at(look_phrase)
			return
		end

		if look_phrase[1] == "in" || look_phrase[1] == "inside"
			look_in(look_phrase)
			return
		end

		if input == "look" || input == "l" || input == "look around"
			@current_message = avatar.location.description
		elsif input == "look closer" || input == "look carefully"
			@current_message = avatar.location.details["phrase"]
		else
			@current_message = "Sorry, I only understand you as far as wanting to look."
		end
	end

	def look_at(look_phrase)

		if look_phrase[0] == "examine"
			careful_look = true
			item = look_phrase[1]
		elsif (look_phrase[1] == "carefully" || look_phrase[1] == "closer") && look_phrase[2] = "at" && !look_phrase[3].nil?
			careful_look = true
			item = look_phrase[3]
		else
			item = look_phrase[2]
		end

		item = inventory_checker(item) || room_checker(item) || character_checker(item)

		if item
			careful_look && item.details ? @current_message = item.details["phrase"] : @current_message = item.description 
		else
			@current_message = "I don't think you can look at anything like that here."
		end			 
	end

	def look_in(look_phrase)

		container = inventory_checker(look_phrase[2]) || room_checker(look_phrase[2]) || character_checker(look_phrase[2])

		if container && (container.open || container.transparent) 
			if container.contents.size == 0
				@current_message = "There's nothing in there but a little bit of lint."
			else
				@current_message = container.list_contents
			end
		elsif !container.open || !container.transparent
			@current_message = "That's closed or not transparent, you can't see inside."
		else
			@current_message = "I don't see any containers like that around here."
		end
	end

	# object checkers

	def inventory_checker(object)
		avatar.items.find do |item|
			item.handle == object || item.alt_handle == object
		end
	end

	def room_checker(object)
		avatar.location.items.find do |item|
			item.handle == object || item.alt_handle == object
		end
	end

	def room_container_checker
		avatar.location.items.select do |item|
			item.container && item.contents && item.open
		end
	end

	def inventory_container_checker
		avatar.items.select do |item|
			item.container && item.contents && item.open
		end
	end

	def room_container(object)
		avatar.location.items.find do |item|
			(item.handle == object || item.alt_handle == object) && item.container
		end
	end

	def carried_container(object)
		avatar.items.find do |item|
			(item.handle == object || item.alt_handle == object) && item.container
		end
	end

	def take_item(object)
		containers = []

		if inventory_checker(object)
			@current_message = "You're already holding that!"
			return
		end

		if room_container_checker.size > 0
			room_container_checker.each do |item|
				containers << item
			end
		end

		if inventory_container_checker.size > 0 
			inventory_container_checker.each do |container|
				containers << container
			end
		end

		if room_checker(object)
		  if !room_checker(object).mobile
		  	@current_message = "It won't budge"
		  	return
	  	end	
			avatar.location.items.each do |item|
				if item.handle == object || item.alt_handle == object
					avatar.items.insert(0, item)
					avatar.location.items.delete(item)
					@current_message = "You've picked up the #{item.handle}"
				end
			end
		else
			@current_message = "Sorry, that doesn't appear to be here."
		end

		containers.each do |container|
			container.contents.each do |item|
				if (item.handle == object || item.alt_handle == object) && (item.mobile.nil? || item.mobile)
				  avatar.items.insert(0, item)
				  container.contents.delete(item)
				  @current_message = "You've picked up the #{item.handle} from the #{container.handle}"	
				  return
				elsif !item.mobile && item.handle == object
					@current_message = "That won't budge."
				end
			end
		end
	end

	def put_in_container(object, container)
		containers = []
		item = inventory_checker(object)

		if room_container_checker.size > 0
			room_container_checker.each do |item|
				containers << item
			end
		end

		if inventory_container_checker.size > 0
			inventory_container_checker.each do |item|
				containers << item
			end
		end

		if item.nil?
			@current_message = "I don't think you're carrying that"
			return
		end

		correct_container = containers.find do |item|
			item.handle == container || item.alt_handle == container
		end

		if correct_container.nil?
			@current_message = "There are no open containers like that here"
			return
		else
			avatar.items.delete(item)
			correct_container.contents.insert(0, item)
		end
		@current_message = "You have placed the #{object} in the #{container}"
	end

	def drop_item(object)
		item = inventory_checker(object)

		if item
			avatar.items.delete(item)
			avatar.location.items.insert(0, item)
			@current_message = "You have dropped the #{object}"
		else
			@current_message = "Ummm I don't think you're carrying that, dude"
		end
	end

	def read_item(object)
		inventory = inventory_checker(object)
		room = room_checker(object)

		if inventory && inventory.letter
			@current_message = inventory.details["phrase"]
			elsif room && room.letter
				@current_message = room.details["phrase"]
		else
			@current_message = "I don't see anything like that to read here."
		end
	end

	def use_keypad
		keypad = avatar.location.items.find do |item|
			item.handle == "keypad"
		end

		if keypad.nil?
			@current_message = "I don't see that here"
			return
		end

		if avatar.location.access_points[keypad.direction]["locked"] == false
			@current_message = "you've already successfully authorized with this keypad, ya big dummy."
			return
		end

		if keypad != nil && keypad.handle == "keypad" 
			puts "your fingers hover over the keypad. what's the code, champ?"
			input = Readline.readline('CODE:', true)

			if input.to_i != 0
				attempt = input.to_i

				if attempt == keypad.code
					@current_message = "that worked! you've unlocked the access point."
					avatar.location.access_points[keypad.direction]["locked"] = false
				else
					@current_message = "i'm sorry, that's incorrect."
				end
			end
		else
			@current_message = "I'm sorry, i don't see a keypad anywhere around here."
		end			
	end

	def unlock_access_point(input, command_two, command_three, command_four, command_five)
		if command_five.nil?
			object = command_four
		else
			object = "#{command_four} #{command_five}"
		end

		avatar.location.access_points.each do |direction, access_point|
			if access_point && access_point["game_handle"] == command_two && access_point["locked"]
				if input == "unlock #{command_two}" && command_three.nil? || command_four.nil?
					@current_message = "What do you want to unlock the #{command_two} with?"
					return
				end
			end

			if access_point["game_handle"] && access_point["game_handle"] == command_two && access_point["locked"] && command_three == "with" && !command_four.nil?
				key = avatar.items.find do |item|
					item.handle == object
				end

				if key.nil?
					@current_message = "I don't think you're carrying that"
					return
				elsif key.code == access_point["code"]
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
		if avatar.items.size > 0
			@current_message = avatar.list_items
		else
			@current_message = "You are not currently carrying anything"
		end
	end

	def open(object)
		room = room_container(object)
		carried = carried_container(object)

		if room.nil? && carried.nil?
			@current_message = "I don't see anything like that to open in here."
			return
		end

		if room.nil? && carried
			# if carried.locked
			# 	@current_message = "That seems to be locked"
			if carried.open
				@current_message = "That's already open"
			else
				@current_message = "You've opened the #{carried.handle}"
				carried.open = true
			end
		elsif carried.nil? && room
			# if room["locked"]
			# 	@current_message = "That seems to be locked"
			if room.open
				@current_message = "That's already open."
			else
				@current_message = "You've opened the #{room.handle}"
				room.open = true
			end
		end
	end

	def close(object)
		room = room_container(object)
		carried = carried_container(object)

		if room.nil? && carried.nil?
			@current_message = "I don't see anything like that to close in here."
			return
		end

		if room.nil? && carried
			if !carried.open
				@current_message = "That seems to be already closed"
			else
				@current_message = "You've closed the #{carried.handle}"
				carried.open = false
			end
		elsif carried.nil? && room
			if !room.open
				@current_message = "That seems to be already closed"
			else
				@current_message = "You've closed the #{room.handle}"
				room.open = false
			end
		end
	end

	def character_checker(name)
		avatar.location.characters.find do |character|
			character.name.downcase == name || character.code_name == name
		end
	end

	def get_answer(character, answer)
		case answer
			when "a"
				response = "'#{character.self_explanation}'"
			when "b"
				response = "'#{character.motive}'"
			when "c"
				response = "'#{character.anything_else}'"
			when "d"
				response = "Ok, goodbye, then."
		else
			response = "'I don't understand that response'"
		end
		response
	end

	def talk_to(name)
		character = character_checker(name)
		if character
				puts "'#{character.response}'"
				answer = character.enter_dialogue	
				while answer != "d" do
					puts get_answer(character, answer)
					answer = character.enter_dialogue
				end
				@current_message = "Ok, goodbye then."
		else
			@current_message = "I don't see anyone like that around here, pilgrim."
		end
	end

	def give_item_to_character(command_two, command_four)
		character = character_checker(command_four)
		item = inventory_checker(command_two)
		# 'give grimsrud rifle' should work the same as 'give rifle to grimsrud'
		if character.nil? || item.nil?
			@current_message = "You either don't have that or that person isn't here."
		elsif character.wants != item.handle
			@current_message = "#{character.name} says: 'I'm sorry but I have no use for that...'"
		else
			avatar.items.delete(item)
			@current_message = "You hand the #{item.handle} to #{character.name}!\n\n#{character.name} says: '#{character.reward}'"
		end
	end

	def two_word_object?(command_two, command_three)
		if command_three.nil?
			object = command_two
		else
			object = "#{command_two} #{command_three}"
		end
		object
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
		command_six   = entered_words[5]

		if command == "go"
			if command_two.nil?
				@current_message = "Ok, what direction do you want to go in?"
				return
			end
			if valid_directions.include?(command_two)
				input_movement(command_two)
			else
				@current_message = "Sorry, that doesn't seem to be a valid direction.."
			end
		end

		if command == "look" || command == "examine"
			look(input)
		end

		if "#{command} #{command_two}" == "talk to"
			talk_to(command_three)
		end

		if command == "open"
			object = two_word_object?(command_two, command_three)
			open(object)
		end

		if command == "put"
			if entered_words.size == 6
				container = "#{command_five} #{command_six}"
				object = "#{command_two} #{command_three}"
			elsif entered_words.size == 5 && (command_three == "in" || command_three == "into")
				# one word object, two-word container
				object = command_two
				container = "#{command_four} #{command_five}"
			elsif entered_words.size == 4
				object = command_two 
				container = command_four
			else
				object = "#{command_two} #{command_three}" 
				container = command_five
			end

			container.strip!
			put_in_container(object, container)
		end

		if command == "close"
			object = two_word_object?(command_two, command_three)
			close(object)
		end
		
		if command == "take" || "#{command} #{command_two}" == "pick up"
			if command == "take"
				object = two_word_object?(command_two, command_three)
			else
				object = two_word_object?(command_three, command_four)
			end
				
			take_item(object)
		end

		if command == "drop"
			object = two_word_object?(command_two, command_three)
			drop_item(object)
		end

		if input == "use keypad"
			use_keypad
		end

		if command == "read"
			read_item(command_two)
		end

		if command == "unlock"
			unlock_access_point(input, command_two, command_three, command_four, command_five)
		end

		if command == "give"
			give_item_to_character(command_two, command_four)
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
		@commands ||= %w(go look l exit quit help h inventory i take pick give drop unlock open close use put read talk examine)
	end

	def valid_directions
		@valid_directions ||= %(up down north south east west)
	end
end