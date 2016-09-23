GAME_ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

require File.join(GAME_ROOT, 'lib', 'bootstrap')
require File.join(GAME_ROOT, 'lib', 'game')

def lookup_file_from(path)
  File.absolute_path(File.join(GAME_ROOT, path))
end

location_data_file = lookup_file_from "#{ARGV[0]}"
message_data_file = lookup_file_from "#{ARGV[1]}"
character_data_file = lookup_file_from "#{ARGV[2]}"
item_data_file = lookup_file_from "#{ARGV[3]}"

bootstrap = Bootstrap.new(location_data_file, message_data_file, character_data_file, item_data_file)
game = Game.new(bootstrap)
game.play