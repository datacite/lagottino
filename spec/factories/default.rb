FactoryBot.define do
  factory :event do    
    uuid { SecureRandom.uuid }
    source_id "citeulike"
    source_token "citeulike_123"
    subj_id "http://www.citeulike.org/user/dbogartoit"
    subj {{ "pid"=>"http://www.citeulike.org/user/dbogartoit",
            "author"=>[{ "given"=>"dbogartoit" }],
            "title"=>"CiteULike bookmarks for user dbogartoit",
            "container-title"=>"CiteULike",
            "issued"=>"2006-06-13T16:14:19Z",
            "URL"=>"http://www.citeulike.org/user/dbogartoit",
            "type"=>"entry" }}
    obj_id "http://doi.org/10.1371/journal.pmed.0030186"
    relation_type_id "bookmarks"
    updated_at { Time.zone.now }
    occurred_at { Time.zone.now }

    factory :event_for_datacite_related do
      source_id "datacite_related"
      source_token "datacite_related_123"
      subj_id "http://doi.org/10.5061/DRYAD.47SD5"
      subj nil
      obj_id "http://doi.org/10.5061/DRYAD.47SD5/1"
      relation_type_id "has_part"
    end
  end
end
