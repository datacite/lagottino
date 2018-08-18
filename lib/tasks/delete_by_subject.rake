namespace :event do
  desc 'Delete events by subj_id'
  task :detete_by_sub_id, [:subj_id] => :environment do |task, args|
    Event.where(subj_id: args[:subj_id]).find_each do |event|
      puts "#{event.uuid} deleted" if event.destroy
    end
  end
end
