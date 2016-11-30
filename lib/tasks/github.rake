namespace :github do
  desc "Push Github usernames to ORCID for all users"
  task :all => :environment do
    User.with_github.find_each do |user|
      GithubJob.perform_later(user)
      puts "Adding Github username to ORCID record for user #{user.orcid}."
    end
  end

  desc "Push Github usernames to ORCID for one user"
  task :one => :environment do
    if ENV['ORCID'].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    user = User.where(uid: ENV['ORCID']).first
    if user.nil?
      puts "User with ORCID #{ENV['ORCID']} does not exist"
      exit
    end

    GithubJob.perform_later(user)
    puts "Adding Github username to ORCID record for user #{user.orcid}."
  end
end
