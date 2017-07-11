module BranchesHelper
	def init_branches
		@branches = Branch.all
		cranches = Array.new
		@branches.each do |k|
	    	tmp = Cranch.new(k.branch_json_url, k.name)
	    	unless tmp.nil?
	    		cranches << tmp
	    	end
		end
		return cranches
	end
end
