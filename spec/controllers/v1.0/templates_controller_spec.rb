RSpec.describe Api::V1x0::TemplatesController, :type => :request do
  # initialize test data
  let(:encoded_user) { encoded_user_hash }
  let(:request_header) { { 'x-rh-identity' => encoded_user } }

  let!(:templates) { create_list(:template, 10) }
  let(:template_id) { templates.first.id }

  let(:api_version) { version }
  let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :admin? => true, :approver? => false, :owner? => false) }

  # Test suite for GET /templates
  describe 'GET /templates' do
    # make HTTP get request before each example
    before do
      allow(RBAC::Access).to receive(:new).with('templates', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api_version}/templates", :params => { :limit => 5, :offset => 0 }, :headers => request_header
    end

    it 'returns templates' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json['links']).not_to be_empty
      expect(json['links']['first']).to match(/limit=5&offset=0/)
      expect(json['links']['last']).to match(/limit=5&offset=5/)
      expect(json['data'].size).to eq(5)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /templates/:id
  describe 'GET /templates/:id' do
    before do 
      allow(RBAC::Access).to receive(:new).with('templates', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api_version}/templates/#{template_id}", :headers => request_header
    end

    context 'when the record exists' do
      it 'returns the template' do
        template = templates.first

        expect(json).not_to be_empty
        expect(json['id']).to eq(template.id.to_s)
        expect(json['created_at']).to eq(template.created_at.iso8601)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let!(:template_id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Template/)
      end
    end
  end
end
