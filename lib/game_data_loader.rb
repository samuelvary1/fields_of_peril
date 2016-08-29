require File.join(File.dirname(__FILE__), 'room')
require 'yaml'

class GameDataLoader
	def load_location_data(file)
		data = load_data_from(file)
		rooms = load_initial_state(data)
		establish_relationships(rooms)
		rooms
  end

	def load_message_data(file)
		load_data_from(file)
	end

	def load_initial_state(data)
		rooms = []
		data.each {|room_data| rooms << build_room(room_data)}
		binding.pry
		rooms
	end

	def establish_relationships(all_rooms)
		all_rooms.each do |room|
			room.rooms.each do |direction, title|
				room.rooms[direction] = all_rooms.find {|r| r.title == title}
			end
		end
	end

	# obviously need to modify this method so it recognizes the CURRENT room you nitwit:

	# def display_items(all_rooms)
	# 	puts "This room currently contains:"
	# 	room.items.each do |name, item_description|
	# 		puts "#{name}: #{item_description}"
	# 	end
	# end

	def build_room(room_data)
		room = get_room
		room.starting_location = room_data["starting_location"]
		room.title = room_data["title"]
		room.header = room_data["header"]
		room.first_time_message = room_data["first_time_message"]
		room.description = room_data["description"]
		room.details = room_data["details"]
		room.items = room_data["items"]
		room.rooms = room_data["rooms"]
		room
	end

	private
	def get_room
    Room.new
	end

	def load_data_from(file)
	  YAML.load_file(file)
	end

end
