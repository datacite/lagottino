namespace :event do
  desc 'Delete events by subj_id'
  task :detete_by_sub_id, [:subj_id] => :environment do |task, args|
    logger = Logger.new(STDOUT)
    events= Event.where(subj_id: args[:subj_id])
    total = events.size
    events.find_each do |event|
      event.destroy
    end
    logger.info "[Event Data] Deleted #{total} event with subj_id #{args[:subj_id]}"
  end
end


