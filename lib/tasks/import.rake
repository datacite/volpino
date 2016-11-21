namespace :import do
  desc "Import works for all users"
  task :all => :environment do
    User.find_each do |user|
      UserJob.perform_later(user)
      puts "Importing works for user #{user.uid}."
    end
  end

  desc "Import works for one user"
  task :one => :environment do |_, args|
    if ENV['ORCID'].nil?
      puts "ENV['ORCID'] is required"
      exit
    end

    user = User.where(uid: ENV['ORCID']).first
    if user.nil?
      puts "User with ORCID #{ENV['ORCID']} does not exist"
      exit
    end

    UserJob.perform_later(user)
    puts "Importing works for user #{user.uid}."
  end
end
