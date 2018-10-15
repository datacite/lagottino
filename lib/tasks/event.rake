namespace :event do
  desc 'Index all events'
  task :index => :environment do
    if ENV['YEAR'].present?
      from_date = "#{ENV['YEAR']}-01-01"
      until_date = "#{ENV['YEAR']}-12-31"
    else
      from_date = ENV['FROM_DATE'] || Date.current.beginning_of_month.strftime("%F")
      until_date = ENV['UNTIL_DATE'] || Date.current.end_of_month.strftime("%F")
    end

    response = Event.index(from_date: from_date, until_date: until_date)
    puts response
  end

  desc 'Index events per day'
  task :index_by_day => :environment do
    from_date = ENV['FROM_DATE'] || Date.current.strftime("%F")

    Event.index_by_day(from_date: from_date)
    puts "Events created on #{from_date} indexed."
  end
end