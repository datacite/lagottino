require 'rails_helper'

describe Client, type: :model do
  describe 'find_by_ids', vcr: true do
    it "ids found" do
      expect(Client.find_by_ids("cdl.cdl,datacite.datacite,dryad.dryad")).to eq("datacite.cdl.cdl"=>"CDL", "datacite.datacite.datacite"=>"DataCite", "datacite.dryad.dryad"=>"DRYAD")
    end

    it "ids not found" do
      expect(Client.find_by_ids("xxx")).to eq({})
    end
  end
end