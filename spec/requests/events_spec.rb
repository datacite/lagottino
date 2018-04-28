require "rails_helper"

describe "/events", :type => :request do
  before(:each) do
    allow(Time).to receive(:now).and_return(Time.mktime(2015, 4, 8))
    allow(Time.zone).to receive(:now).and_return(Time.mktime(2015, 4, 8))
  end

  let(:event) { build(:event) }
  let(:errors) { [{"status"=>"401", "title"=>"You are not authorized to access this resource."}] }

  # Successful response from creating via the API.
  let(:success) { { "id"=> event.uuid,
                    "subj_id"=>"http://doi.org/10.1371/journal.pmed.0030186",
                    "obj_id"=>"http://www.citeulike.org/user/dbogartoit",
                    "message_action"=>"create",
                    "source_token"=>"citeulike_123",
                    "relation_type_id"=>"bookmarks",
                    "source_id"=>"citeulike",
                    "total"=>1,
                    "license"=>"https://creativecommons.org/publicdomain/zero/1.0/",
                    "occurred_at"=>"2015-04-08T00:00:00.000Z",
                    "timestamp"=>"2015-04-08T00:00:00Z",
                    "subj"=>{},
                    "obj"=> {"pid"=>"http://www.citeulike.org/user/dbogartoit",
                              "author"=>[{"given"=>"dbogartoit"}],
                              "title"=>"CiteULike bookmarks for user dbogartoit",
                              "container_title"=>"CiteULike",
                              "issued"=>"2006-06-13T16:14:19Z",
                              "url"=>"http://www.citeulike.org/user/dbogartoit",
                              "type"=>"entry"}
                    }}

  let(:token) { User.generate_token(role_id: "staff_admin") }
  let(:uuid) { SecureRandom.uuid }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/json",
      "HTTP_AUTHORIZATION" => "Bearer #{token}" }
  end

  context "create" do
    let(:uri) { "/events" }
    let(:params) do
      { 
        "uuid" => event.uuid,
        "subj_id" => event.subj_id,
        "subj" => event.subj,
        "obj_id" => event.obj_id,
        "relation_type_id" => event.relation_type_id,
        "source_id" => event.source_id,
        "source_token" => event.source_token }
    end

    context "as admin user" do
      it "JSON" do
        post uri, params, headers
        puts last_response.body
        expect(last_response.status).to eq(201)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("event", "subj_id")).to eq("http://doi.org/10.1371/journal.pmed.0030186")
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["event"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["event"]).to be_blank
      end
    end

    context "without source_token" do
      let(:params) do
        { 
          "uuid" => uuid,
          "subj_id" => event.subj_id,
          "source_id" => event.source_id }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source token can't be blank"}])
        expect(response["event"]).to be_nil
      end
    end

    context "without source_id" do
      let(:params) do
        { 
          "uuid" => uuid,
          "subj_id" => event.subj_id,
          "source_token" => event.source_token }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source can't be blank"}])
        expect(response["event"]).to be_blank
      end
    end

    context "without subj_id" do
      let(:params) do
        { 
          "uuid" => uuid,
          "source_id" => event.source_id,
          "source_token" => event.source_token }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Subj can't be blank"}])
        expect(response["event"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["event"]).to be_nil
      end
    end

    context "with unpermitted params" do
      let(:params) do
        { 
          "uuid" => uuid,
          "subj_id" => event.subj_id,
          "source_id" => event.source_id,
          "source_token" => event.source_token,
          "foo" => "bar" }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>"422", "title"=>"found unpermitted parameter: :foo"}])
        expect(response["event"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "title" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)
        response = JSON.parse(last_response.body)
        error = response["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("found unpermitted parameter: :title")
        expect(response["event"]).to be_nil
      end
    end
  end

  context "show" do
    let(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    context "as admin user" do
      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["event"]).to eq(success)
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["event"]).to eq(success)
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["event"]).to eq(success)
      end
    end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(response["events"]).to be_nil
      end
    end
  end

  context "index" do
    let!(:event) { create(:event) }
    let(:uri) { "/events" }

    # Just test that the API can be accessed without a token.
    context "with no API key" do

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json" }
      end

      it "JSON" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        expect(response["events"]).to eq([success])
      end

      it "No accept header" do
        get uri

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        expect(response["events"]).to eq([success])
      end
    end

    context "query by subj_id" do
      let(:uri) { "/events?subj-id=#{event.subj_id}" }

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json" }
      end

      it "s" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        puts success.to_json
        expect(response["events"]).to eq([success])
      end
    end

    context "query by unknown subj_id" do
      let(:uri) { "/events?subj-id=xxx" }

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json" }
      end

      it "s" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        expect(response["events"]).to be_empty
      end
    end

    context "query by source_id" do
      let(:uri) { "/events?source-id=citeulike" }

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json" }
      end

      it "s" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        expect(response["events"]).to eq([success])
      end
    end

    context "query by state" do
      let(:uri) { "/events?state=waiting" }

      # Exclude the token header.
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json" }
      end

      it "s" do
        get uri, nil, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)

        expect(response["errors"]).to be_nil
        expect(response["events"]).to eq([success])
      end
    end
  end

  context "destroy" do
    let(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    context "as admin user" do
      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response["events"]).to be_nil
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["events"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["events"]).to be_nil
      end
    end

    context "with wrong API key" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json",
          "HTTP_AUTHORIZATION" => "Token token=12345678" }
      end

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["events"]).to be_nil
      end
    end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(response["events"]).to be_nil
      end
    end
  end
end
