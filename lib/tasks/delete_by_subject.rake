namespace :event do
  desc 'Delete events by subject'
  task :detete_by_subject, [:subj_id] => :environment do |task, args|
    collection = Event.where(subj_id: args[:subj_id])
    uuids = collection.map { |i|  i[:uuid]  }
    uuids.each do |uuid| 
      puts "#{uuid} deleted" if Event.where(uuid: uuid).first.delete.destroyed?
    end
  end
end
