require File.join(File.dirname(__FILE__), 'room')
require File.join(File.dirname(__FILE__), 'character')
require 'yaml'

class GameDataLoader
	def load_location_data(location_data_file, character_data_file)
		room_data = load_data_from(location_data_file)
		character_data = load_data_from(character_data_file)
		characters = load_initial_characters_state(character_data)
		rooms = load_initial_state(room_data, characters)
		establish_relationships(rooms)
		rooms
  end

	def load_message_data(file)
		load_data_from(file)
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

	def load_initial_state(data, characters)
		rooms = []
		data.each {|room_data| rooms << build_room(room_data)}
		rooms.each do |room|
			characters.each do |character|
				if character.lives_in == room.title
					room.characters << character
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
		room.starting_location = room_data["starting_location"]
		room.title = room_data["title"]
		room.header = room_data["header"]
		room.first_time_message = room_data["first_time_message"]
		room.description = room_data["description"]
		room.details = room_data["details"]
		
		if room_data["items"].nil?
			room.items = []
		else	
			room.items = room_data["items"]
		end
		
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

	private
	def get_room
    Room.new
	end

	def get_character
		Character.new
	end

	def load_data_from(file)
	  YAML.load_file(file)
	end

end
