require File.join(File.dirname(__FILE__), 'room')
require File.join(File.dirname(__FILE__), 'character')
require File.join(File.dirname(__FILE__), 'item')
require 'yaml'

class GameDataLoader
	def load_location_data(location_data_file, character_data_file, item_data_file)
		
		character_data = load_data_from(character_data_file)
		characters = load_initial_characters_state(character_data)
		
		item_data = load_data_from(item_data_file)
		items = load_initial_items_state(item_data)

		room_data = load_data_from(location_data_file)
		rooms = load_initial_state(room_data, characters, items)

		establish_relationships(rooms)
		rooms
  end

	def load_message_data(file)
		load_data_from(file)
	end

	def load_item_data(file)
		data = load_data_from(file)
		items = load_initial_items_state(data)
		items
	end

	def load_initial_items_state(data)
		items = []
		data.each {|item_data| items << build_item(item_data)}
		items
	end

	def load_character_data(file)
		data = load_data_from(file)
		characters = load_initial_characters_state(data)
		characters
	end

	def load_initial_characters_state(data)
		characters = []
		data.each {|character_data| characters << build_character(character_data)}
		characters
	end

	def load_initial_state(data, characters, items)
		rooms = []
		data.each {|room_data| rooms << build_room(room_data)}
		rooms.each do |room|
			characters.each do |character|
				if character.lives_in == room.title
					room.characters << character
				end
			end
			items.each do |item|
				if item.location == room.title
					room.items << item
				end
			end
		end
		rooms
	end

	def establish_relationships(all_rooms)
		all_rooms.each do |room|
			room.rooms.each do |direction, title|
				room.rooms[direction] = all_rooms.find {|r| r.title == title}
			end
		end
	end

	def build_room(room_data)
		room = get_room
		room.characters = []
		room.items = []
		room.starting_location = room_data["starting_location"]
		room.title = room_data["title"]
		room.header = room_data["header"]
		room.first_time_message = room_data["first_time_message"]
		room.description = room_data["description"]
		room.details = room_data["details"]
		
		# if room_data["items"].nil?
		# 	room.items = []
		# else	
		# 	room.items = room_data["items"]
		# end
		
		room.rooms = room_data["rooms"]
		room.access_points = room_data["access_points"]
		room.been_before = false
		room
	end

	def build_character(character_data)
		character = get_character
		character.name = character_data["name"]
		character.response = character_data["response"]
		character.lives_in = character_data["lives_in"]
		character
	end

	def build_item(item_data)
		item = get_item
		item.handle = item_data["handle"]
		item.description = item_data["description"]
		item.details = item_data["details"]
		item.location = item_data["location"]
		item.container = item_data["container"]
		item.open = item_data["open"]
		item.transparent = item_data["transparent"]
		item.mobile = item_data["mobile"]
		item.letter = item_data["letter"]
		item.mobile.nil? ? item.mobile = true : item.mobile = false
		item.letter.nil? ? item.letter = false : item.letter = false
		item.direction = item_data["direction"]
		item.locked = item_data["locked"]
		item.code = item_data["code"]
		item.contents = item_data["contents"]
		item
	end

	private
	def get_room
    Room.new
	end

	def get_character
		Character.new
	end

	def get_item
		Item.new
	end

	def load_data_from(file)
	  YAML.load_file(file)
	end

end
