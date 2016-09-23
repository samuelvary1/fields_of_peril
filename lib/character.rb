class Character
	attr_accessor :name, :code_name, :lives_in, :description, :response, :self_explanation, :motive, :anything_else, :wants, :reward

	def enter_dialogue
		puts "'#{response}'"
		puts ""
		puts "a) who are you?"
		puts "b) what do you want?"
		puts "c) anything else I should know?"
		puts "d) goodbye."
		puts ""

		answer = Readline.readline('> ', true)

	end
end