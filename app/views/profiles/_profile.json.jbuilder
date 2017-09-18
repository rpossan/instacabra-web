json.extract! profile, :id, :username, :ripped, :created_at, :updated_at
json.url profile_url(profile, format: :json)