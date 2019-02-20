FactoryBot.define do
  factory :event do    
    uuid { SecureRandom.uuid }
    source_id { "citeulike" }
    source_token { "citeulike_123" }
    sequence(:subj_id) { |n| "http://www.citeulike.org/user/dbogartoit/#{n}" }
    obj_id { "http://doi.org/10.1371/journal.pmed.0030186" }
    subj {{ "@id"=>"http://www.citeulike.org/user/dbogartoit",
            "@type"=>"CreativeWork",
            "uid"=>"http://www.citeulike.org/user/dbogartoit",
            "author"=>[{ "given"=>"dbogartoit" }],
            "name"=>"CiteULike bookmarks for user dbogartoit",
            "publisher"=>"CiteULike",
            "date-published"=>"2006-06-13T16:14:19Z",
            "url"=>"http://www.citeulike.org/user/dbogartoit" }}
    obj {}
    relation_type_id { "bookmarks" }
    updated_at { Time.zone.now }
    occurred_at { Time.zone.now }

    factory :event_for_datacite_related do
      source_id { "datacite_related" }
      source_token { "datacite_related_123" }
      subj_id { "http://doi.org/10.5061/DRYAD.47SD5" }
      subj { nil }
      obj_id { "http://doi.org/10.5061/DRYAD.47SD5/1" }
      relation_type_id { "has_part" }
    end
  end
end
