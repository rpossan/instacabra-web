class Job < ApplicationRecord

	has_many :profiles

	def days_ago
		Time.now.day - created_at.day
	end

	def completed
		profiles.where(ripped: true)
	end

	def percent
		(ripped_media.to_f / total_media.to_f) * 100
	end
end
