namespace :event do
  desc 'Index all events'
  task :index => :environment do
    from_id = (ENV['FROM_ID'] || 1).to_i
    until_id = (ENV['UNTIL_ID'] || from_id + 499).to_i

    Event.index(from_id: from_id, until_id: until_id)
  end
end