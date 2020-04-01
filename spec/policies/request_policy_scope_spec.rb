describe RequestPolicy::Scope do
  include_context "approval_rbac_objects"

  let!(:requests) { create_list(:request, 3) }
  let!(:sub_requests) { create_list(:request, 2, :parent_id => requests.first.id) }
  let(:access) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:user) { instance_double(UserContext, :access => access, :rbac_enabled? => true) }
  let(:subject) { described_class.new(user, scope) }
  let(:headers_with_admin) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/admin') }
  let(:headers_with_approver) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/approver') }
  let(:headers_with_requester) { RequestSpecHelper.default_headers.merge(Insights::API::Common::Request::PERSONA_KEY => 'approval/requester') }
  let(:headers) { {:headers => req_headers, :original_url=>'url'} }

  describe '#resolve /requests' do
    let(:scope) { Request }

    context 'when admin role' do
      let(:req_headers) { headers_with_admin }
      before { allow(access).to receive(:scopes).and_return(['admin']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve).to match_array(requests)
        end
      end
    end

    context 'when approver role' do
      let(:req_headers) { headers_with_approver }
      before do
        allow(subject).to receive(:approver_id_list).and_return([requests.first.id, requests.last.id])
        allow(access).to receive(:scopes).and_return(['group'])
      end

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve.sort).to eq(Request.where(:id => [requests.first.id, requests.last.id]).sort)
        end
      end
    end

    context 'when requester role' do
      let(:req_headers) { headers_with_requester }
      before do
        allow(subject).to receive(:owner_id_list).and_return([requests.second.id])
        allow(access).to receive(:scopes).and_return(['user'])
      end

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve.count).to eq(1)
          expect(subject.resolve.first).to eq(requests.second)
        end
      end
    end
  end

  describe '#resolve /requests/#{id}/requests' do
    let!(:scope) { requests.first.children }

    context 'when admin role' do
      let(:req_headers) { headers_with_admin }
      before { allow(access).to receive(:scopes).and_return(['admin']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve).to match_array(sub_requests)
        end
      end
    end

    context 'when regular user role' do
      let(:req_headers) { headers_with_requester }
      before { allow(access).to receive(:scopes).and_return(['user']) }

      it 'returns requests' do
        Insights::API::Common::Request.with_request(headers) do
          expect(subject.resolve).to match_array(sub_requests)
        end
      end
    end

  end
end