namespace :deposit do
  desc "Deposit works for all users"
  task :all => :environment do
    Claim.search_and_link.each do |claim|
      DepositJob.perform_later(claim)
      puts "Depositing claim #{claim.doi} for user #{claim.orcid}."
    end
  end
end
