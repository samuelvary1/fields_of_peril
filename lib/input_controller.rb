class InputController
	attr_reader :avatar, :current_message
	
	def avatar=(avatar)
		@avatar = avatar
		# binding.pry
	end

	def messages=(messages)
		@messages = messages
	end

	def initialize_message
		@current_message = "#{avatar.location.header}\n #{avatar.location.first_time_message}"	
	end

	def evaluate(input)
		entered_words = input.split
		
		entered_words.each do |word|
			word.downcase!
		end

		unless valid?(input)
			@current_message = "Sorry, that is not a valid command."
			return
		end		

		command = entered_words.first

		if command == "go"
			direction = entered_words.last
			if avatar.can_move?(direction)
				avatar.move(direction)
				@current_message = "#{avatar.location.header}\n #{avatar.location.first_time_message}"
			else
				@current_message = "Sorry, you cannot go #{direction} from here."
			end
		end	

		if entered_words == ["look", "closer"]
			@current_message = avatar.location.details
			return
		end

		if command == "look"
			@current_message = avatar.location.description
		end

		if command == "inventory" || command == "i"
			if avatar.items == {}
				@current_message = "You are not currently carrying anything"
			else
				@current_message = "You are currently carrying:\n"
				avatar.items.each do |name, description|
					puts "#{name}: #{description}"
				end
			end
		end
		
		if command == "help"
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
		elsif entered_words.size == 2
			result = true
		end
		result
	end

	def valid_commands
		@commands ||= %w(look exit quit help inventory i)
	end

end
