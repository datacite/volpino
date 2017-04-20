# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'csv'

csv_text = File.read(Rails.root.join('lib', 'seeds', 'funderNames.csv'))
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  t = Funder.new
  t.fundref_id = row['uri']
  t.name = row['primary_name_display']
  t.replaced = row['replaced']
  t.save
  puts "#{t.fundref_id}, #{t.name} saved"
end

puts "There are now #{Funder.count} rows in the funders table"
