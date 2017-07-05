class Intern
	@sleep_hours = 0;
	
	def initialize(hours)
		@sleep_hours = hours;
	end
	def sleep(hours)
		@sleep_hours += hours;
	end

	

	def complain
		puts "I slept only for #@sleep_hours hours!";
	end
end

Yves = Intern.new(10);
Yves.complain();
Yves.sleep(10);
Yves.complain();
