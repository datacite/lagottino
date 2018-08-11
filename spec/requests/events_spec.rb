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
                    "type"=>"events",
                    "attributes"=>{
                      "subj-id"=>"http://www.citeulike.org/user/dbogartoit",
                      "obj-id"=>"http://doi.org/10.1371/journal.pmed.0030186",
                      "message-action"=>"create",
                      "source-token"=>"citeulike_123",
                      "relation-type-id"=>"bookmarks",
                      "source-id"=>"citeulike",
                      "total"=>1,
                      "license"=>"https://creativecommons.org/publicdomain/zero/1.0/",
                      "occurred-at"=>"2015-04-08T00:00:00.000Z",
                      "subj"=> {"pid"=>"http://www.citeulike.org/user/dbogartoit",
                               "author"=>[{"given"=>"dbogartoit"}],
                               "title"=>"CiteULike bookmarks for user dbogartoit",
                               "container-title"=>"CiteULike",
                               "issued"=>"2006-06-13T16:14:19Z",
                               "url"=>"http://www.citeulike.org/user/dbogartoit",
                               "type"=>"entry"
                      },
                      "obj"=>{}}}}

  let(:token) { User.generate_token(role_id: "staff_admin") }
  let(:uuid) { SecureRandom.uuid }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/json",
      "HTTP_AUTHORIZATION" => "Bearer #{token}" }
  end

  context "create" do
    let(:uri) { "/events" }
    let(:params) do
      { "data" => { "type" => "events",
                    "attributes" => {
                      "subj-id" => event.subj_id,
                      "subj" => event.subj,
                      "obj-id" => event.obj_id,
                      "relation-type-id" => event.relation_type_id,
                      "source-id" => event.source_id,
                      "source-token" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(201)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "id")).not_to eq(event.uuid)
        expect(response.dig("data", "attributes", "subj-id")).to eq("http://www.citeulike.org/user/dbogartoit")
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_blank
      end
    end

    context "without source-token" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "subj-id" => event.subj_id,
                        "source-id" => event.source_id } } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source token can't be blank"}])
        expect(response["data"]).to be_nil
      end
    end

    context "without source-id" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "subj-id" => event.subj_id,
                        "source-token" => event.source_token } } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source can't be blank"}])
        expect(response["data"]).to be_blank
      end
    end

    context "without subj-id" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "source-id" => event.source_id,
                        "source-token" => event.source_token } } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Subj can't be blank"}])
        expect(response["data"]).to be_blank
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
        expect(response["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                         "attributes" => {
                           "uuid" => uuid,
                           "source-token" => "123" } } }
      end

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        post uri, params, headers
        expect(last_response.status).to eq(422)
        response = JSON.parse(last_response.body)
        error = response["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
      end
    end

    context "duplicate entry" do
      let!(:event) { create(:event) }

      it "JSON" do
        post uri, params, headers

        expect(last_response.status).to eq(409)

        response = JSON.parse(last_response.body)
        error = response["errors"].first
        expect(error["status"]).to eq("409")
        expect(error["title"]).to eq("The resource already exists.")
        expect(response["data"]).to be_blank
      end
    end
  end

  context "upsert" do
    let(:uri) { "/events/#{event.uuid}" }
    let(:params) do
      { "data" => { "type" => "events",
                    "id" => event.uuid,
                    "attributes" => {
                      "uuid" => event.uuid,
                      "subj-id" => event.subj_id,
                      "subj" => event.subj,
                      "obj-id" => event.obj_id,
                      "relation-type-id" => event.relation_type_id,
                      "source-id" => event.source_id,
                      "source-token" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(201)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "id")).to eq(event.uuid)
        expect(response.dig("data", "attributes", "subj-id")).to eq("http://www.citeulike.org/user/dbogartoit")
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_blank
      end
    end

    context "without source-token" do
      let(:params) do
        { "data" => { "type" => "events",
            
                      "attributes" => {
                        "uuid" => uuid,
                        "subj-id" => event.subj_id,
                        "source-id" => event.source_id } } }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source token can't be blank"}])
        expect(response["data"]).to be_nil
      end
    end

    context "without source-id" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "subj-id" => event.subj_id,
                        "source-token" => event.source_token } } }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Source can't be blank"}])
        expect(response["data"]).to be_blank
      end
    end

    context "without subj-id" do
      let(:params) do
        { "data" => { "type" => "events",
                      "attributes" => {
                        "uuid" => uuid,
                        "source-id" => event.source_id,
                        "source-token" => event.source_token } } }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>422, "title"=>"Subj can't be blank"}])
        expect(response["data"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                         "attributes" => {
                           "uuid" => uuid,
                           "source-token" => "123" } } }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)
        response = JSON.parse(last_response.body)
        error = response["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
      end
    end

    context "entry already exists" do
      let!(:event) { create(:event) }

      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "subj-id")).to eq("http://www.citeulike.org/user/dbogartoit")
      end
    end
  end

  context "update" do
    let(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    let(:params) do
      { "data" => { "type" => "events",
                    "id" => event.uuid,
                    "attributes" => {
                      "subj-id" => event.subj_id,
                      "subj" => event.subj,
                      "obj-id" => event.obj_id,
                      "relation-type-id" => event.relation_type_id,
                      "source-id" => event.source_id,
                      "source-token" => event.source_token } } }
    end

    context "as admin user" do
      it "JSON" do
        put uri, params, headers

        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to be_nil
        expect(response.dig("data", "attributes", "subj-id")).to eq("http://www.citeulike.org/user/dbogartoit")
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_blank
      end
    end

    context "with wrong API token" do
      let(:headers) do
        { "HTTP_ACCEPT" => "application/json",
          "HTTP_AUTHORIZATION" => "Bearer 12345678" }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_blank
      end
    end

    context "with missing data param" do
      let(:params) do
        { "event" => { "type" => "events",
                       "id" => uuid,
                       "attributes" => {
                         "source-token" => "123" } } }
      end

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)

        response = JSON.parse(last_response.body)
        expect(response.dig("errors", 0, "title")).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
      end
    end

    context "with params in wrong format" do
      let(:params) { { "data" => "10.1371/journal.pone.0036790 2012-05-15 New Dromaeosaurids (Dinosauria: Theropoda) from the Lower Cretaceous of Utah, and the Evolution of the Dromaeosaurid Tail" } }

      it "JSON" do
        put uri, params, headers
        expect(last_response.status).to eq(422)
        response = JSON.parse(last_response.body)
        error = response["errors"].first
        expect(error["status"]).to eq("422")
        expect(error["title"]).to start_with("Invalid payload")
        expect(response["data"]).to be_blank
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
        attributes = response.dig("data", "attributes")
        expect(attributes["subj-id"]).to eq(event.subj_id)
      end
    end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        attributes = response.dig("data", "attributes")
        expect(attributes["subj-id"]).to eq(event.subj_id)
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(200)

        response = JSON.parse(last_response.body)
        attributes = response.dig("data", "attributes")
        expect(attributes["subj-id"]).to eq(event.subj_id)
      end
    end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        get uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(response["data"]).to be_nil
      end
    end
  end

  context "index" do
    let!(:event) { create(:event) }
    let(:uri) { "/events" }

    # Just test that the API can be accessed without a token.
    # context "with no API key" do

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "JSON" do
    #     sleep 1
    #     get uri, nil, headers
    #     puts last_response.body

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end

    #   it "No accept header" do
    #     sleep 1
    #     get uri

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end

    # context "query by obj-id" do
    #   let(:uri) { "/events?obj-id=#{event.obj_id}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by subj-id" do
    #   let(:uri) { "/events?subj-id=#{event.subj_id}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end

    # context "query by unknown subj-id" do
    #   let(:uri) { "/events?subj-id=xxx" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)

    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to be_empty
    #   end
    # end

    # context "query by obj-id as doi" do
    #   let(:doi) { "10.1371/journal.pmed.0030186" }
    #   let(:event) { create(:event, obj_id: doi) }
    #   let(:uri) { "/events?obj-id=#{doi}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by doi as doi" do
    #   let(:doi) { "10.1371/journal.pmed.0030186" }
    #   let(:event) { create(:event, obj_id: doi) }
    #   let(:uri) { "/events?doi=#{doi}" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["obj-id"]).to eq(event.obj_id)
    #   end
    # end

    # context "query by unknown obj-id" do
    #   let(:uri) { "/events?obj-id=xxx" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)

    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to be_empty
    #   end
    # end

    # context "query by source-id" do
    #   let(:uri) { "/events?source-id=citeulike" }

    #   # Exclude the token header.
    #   let(:headers) do
    #     { "HTTP_ACCEPT" => "application/json" }
    #   end

    #   it "json" do
    #     get uri, nil, headers

    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     attributes = response.dig("data", 0, "attributes")
    #     expect(attributes["subj-id"]).to eq(event.subj_id)
    #   end
    # end
  end

  context "destroy" do
    let(:event) { create(:event) }
    let(:uri) { "/events/#{event.uuid}" }

    # context "as admin user" do
    #   it "JSON" do
    #     delete uri, nil, headers
    #     expect(last_response.status).to eq(200)

    #     response = JSON.parse(last_response.body)
    #     expect(response["errors"]).to be_nil
    #     expect(response["data"]).to eq({})
    #   end
    # end

    context "as staff user" do
      let(:token) { User.generate_token(role_id: "staff_user") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_nil
      end
    end

    context "as regular user" do
      let(:token) { User.generate_token(role_id: "user") }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(401)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq(errors)
        expect(response["data"]).to be_nil
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
        expect(response["data"]).to be_nil
      end
    end

    context "event not found" do
      let(:uri) { "/events/#{event.uuid}x" }

      it "JSON" do
        delete uri, nil, headers
        expect(last_response.status).to eq(404)

        response = JSON.parse(last_response.body)
        expect(response["errors"]).to eq([{"status"=>"404", "title"=>"The resource you are looking for doesn't exist."}])
        expect(response["data"]).to be_nil
      end
    end
  end
end