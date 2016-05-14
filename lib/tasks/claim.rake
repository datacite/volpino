namespace :claim do
  desc "Push all stale claims"
  task :stale => :environment do
    Claim.stale.each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing stale claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all failed claims"
  task :failed => :environment do
    Claim.failed.each do |claim|
      ClaimJob.perform_later(claim)
      puts "Pushing failed claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end

  desc "Push all ignored claims"
  task :ignored => :environment do
    Claim.ignored.each do |claim|
      # skip if not user account
      next unless claim.user.present?

      ClaimJob.perform_later(claim)
      puts "Pushing ignored claim #{claim.doi} for user #{claim.orcid} to ORCID."
    end
  end
end
