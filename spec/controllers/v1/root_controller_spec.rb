RSpec.describe Api::V1x0::RootController, :type => [:request, :v1x2] do
  let(:encoded_user) { encoded_user_hash }

  context "v1" do
    it "#openapi.json" do
      get "#{api_version}/openapi.json"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "redirects properly" do
      get "#{api_version.split('.').first}/openapi.json"

      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq("#{api_version}/openapi.json")
    end
  end
end
