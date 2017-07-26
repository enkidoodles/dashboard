module BranchesHelper
	def init_branches
		@branches = Branch.all
		cranches = Array.new
		@branches.each do |k|
	    	tmp = Cranch.new(k.branch_json_url, k.name, k.displayAlert, k.alertMessage)
	    	unless tmp.nil?
	    		cranches << tmp
	    	end
		end
		return cranches
	end

	def commiter(a, b)
		return a.nil? ? b : a
	end
end
