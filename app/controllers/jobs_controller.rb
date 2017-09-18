class JobsController < ApplicationController
  before_action :set_job, only: [:show, :edit, :update, :destroy, :status, :download]

  def download
    path = "tmp/downloads/"
    folder_name = @job.created_at.strftime("%Y%m%d%H%M")
    folder = path + folder_name
    zipfile_name = folder + "/#{folder_name}.zip"

    #If zip file not created, create zip file else downlaoad created
    if not File.file?(zipfile_name)
      require 'zip'
      files = []

      @job.profiles.each do |p|
        files << p.username + ".json"
      end

      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        files.each do |filename|
          zipfile.add(filename, folder + '/' + filename)
        end
      end
    end

    send_file(File.open zipfile_name)

  end

  def status
    @percent = @job.percent
    @percent = 1 if @percent <= 1
    @percent = 100 if @job.done? or @percent > 100
    @percent = @percent.to_i
    @completed = @job.completed.count
    @total = @job.profiles.count
    render layout: false
  end

  def update

    Sidekiq::Queue.new("ripper").clear
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear

    @job.update_attribute(:done, true)
    redirect_to jobs_url
  end

  # GET /jobs
  # GET /jobs.json
  def index
    @jobs = Job.all.where(done: true).order(id: "desc")
    @job = Job.where(done: false).last
    @job = Job.new if @job.nil?
  end


  # POST /jobs
  # POST /jobs.json
  def create

    return redirect_to action: :index if params[:input_file].blank? && params[:job]["input"].blank?

    max = 0 # Set 0 to get all posts from profile
    @job = Job.new(job_params)

    profiles_input = []

    profiles_input << [params[:job]["input"], 0] if params[:input_file].blank?

    if not params[:input_file].blank?
      file = params[:input_file]
      json = file.read
      json = JSON.parse json
      json.each do |profile|
        profiles_input << [profile[0], profile[1]]
      end
    end

    has_location = (params[:has_location] == "on")

    profiles_input.each do |p|
      profile = Profile.new
      
      begin
        if p[0].is_a? Integer
          instagram_profile = Instagram::Location.new p[0].to_i
          profile.is_location = true
        else
          instagram_profile = Instagram::Profile.new p[0].to_s
        end
        @job.total_profiles += 1
        @job.total_media += get_max(max, instagram_profile.media_count)
        profile.total_media = get_max(max, instagram_profile.media_count)
        profile.username = p[0].to_s
        profile.from_date = p[1].to_i
        @job.profiles << profile
      rescue
        puts "[ERROR] Error to try to find profile <#{p[0]}>!"
      end

    end

    respond_to do |format|
      if @job.save
        @job.profiles.each do |profile|
          RipperWorker.perform_async(profile.username.to_s, params[:media_type], has_location)
        end
        format.html { redirect_to action: index, notice: 'Job was successfully created.' }
        format.json { render :show, status: :created, location: @job }
      else
        format.html { render :index }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job.destroy
    respond_to do |format|
      format.html { redirect_to jobs_url, notice: 'Job was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def get_max(max, profile_total)
      total = max
      total = profile_total if(max == 0 || max >= profile_total)
      return total
    end

    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params.require(:job).permit(:input)
    end
end
