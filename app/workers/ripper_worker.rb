class RipperWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'ripper'

  def perform(username, type = "all", has_location = false, max = 0)

    profile = Profile.where(username: username).last
    job = profile.job

    path = "tmp/downloads/"
    folder_name = job.created_at.strftime("%Y%m%d%H%M")
    folder_path = path + folder_name

    Dir.mkdir folder_path unless File.directory?(folder_path)

    batch_size = 10
    
    #If max is not set, fetch all profile media
    #max = job.total_media if max == 0

    max = profile.total_media if max == 0

    if max == 0
      puts "======> #{profile.username} - ZERO MEDIA - From: #{profile.from_date}"
      json_file = File.open("#{path + folder_name}/#{profile.username}.json","w")
      json_hash = {
        pagination: { next_url: "", next_max_id: "" },
        meta: {code: 200},
        data: []
      }
      ActiveRecord::Base.transaction do
        json_file.write(json_hash.to_json) # Write to file json output
        profile.update_attribute(:ripped, true) # Update Job status
        json_file.close
        job.update_attribute(:done, true) if job.profiles.where(ripped: true).size >= job.profiles.size 
      end
      return
    end

    cycles = (max / batch_size).to_i
    cycles = cycles + 1 if (max % batch_size) != 0

    if profile.is_location?
      p = Instagram::Location.new profile.username.to_i
    else
      p = Instagram::Profile.new profile.username.to_s
    end
    json_file = File.open("#{path + folder_name}/#{profile.username}.json","w")
    json_hash = {
      pagination: { next_url: "", next_max_id: "" },
      meta: {code: 200},
      data: []
    }
    data_arr = []
    offset = 1
    limit = batch_size

    # If it has one cycle and lower than max total media of profile
    limit = profile.total_media if cycles <= 1

    1.upto(cycles) do
      break if limit > profile.total_media
      puts "======> #{profile.username} - #{offset}..#{limit} - From: #{profile.from_date}"
      # Fetch in batch
      if type == "all"
        p.fetch_media offset..limit, { has_location: has_location, from: profile.from_date }
      elsif type == "photos"
        p.fetch_photos offset..limit, { has_location: has_location, from: profile.from_date }
      elsif type == "videos"
        p.fetch_videos offset..limit, { has_location: has_location, from: profile.from_date }
      end
      data_arr = data_arr + p.extract_data # Extract data from batch ripped
      
      offset = limit + 1
      ripped = limit 
      limit += batch_size
      limit = profile.total_media if limit > profile.total_media

      ActiveRecord::Base.transaction do
        job.update_attribute(:ripped_media, ripped) # Update ripped data
      end
    end

    data_arr.each {|data| json_hash[:data] << data } # Input data into json hash
      ActiveRecord::Base.transaction do
        json_file.write(json_hash.to_json) # Write to file json output
        profile.update_attribute(:ripped, true) # Update Job status
        json_file.close
        job.update_attribute(:done, true) if job.profiles.where(ripped: true).size >= job.profiles.size 
          
        p.close_connection! # Close connection with webdriver
      end
    end
end