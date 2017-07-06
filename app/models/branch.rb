class Branch < ApplicationRecord
	validates :name, presence: true
	validates :branch_json_url, presence: true
	validates_format_of :branch_json_url, :with => URI::regexp(%w(http https))
end
