namespace :github do
  desc "Push Github usernames to ORCID for all users"
  task :all => :environment do
    User.all.each do |user|
      GithubJob.perform_later(user)
      puts "Adding Github username to ORCID record for user #{user.orcid}."
    end
  end
end
