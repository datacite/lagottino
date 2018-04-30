require 'rails_helper'

describe "Identifiable", vcr: true do
  subject  { create(:event) }

  it 'normalize_doi https' do
    doi = "https://doi.org/10.1371/journal.pmed.0030186"
    expect(subject.normalize_doi(doi)).to eq("https://doi.org/10.1371/journal.pmed.0030186")
  end

  it 'normalize_doi http' do
    doi = "https://doi.org/10.1371/journal.pmed.0030186"
    expect(subject.normalize_doi(doi)).to eq("https://doi.org/10.1371/journal.pmed.0030186")
  end

  it 'normalize_doi doi' do
    doi = "10.1371/journal.pmed.0030186"
    expect(subject.normalize_doi(doi)).to eq("https://doi.org/10.1371/journal.pmed.0030186")
  end
end