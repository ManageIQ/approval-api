RSpec.shared_context "tag_resource_objects" do
  let(:tenant1) { create(:tenant) }
  let(:tenant2) { create(:tenant, :external_tenant => 'fred') }
  let(:tenant1_workflows) { create_list(:workflow, 2, :tenant => tenant1) }
  let(:workflow1) { tenant1_workflows[1] }
  let(:wf1_tag)   { "/approval/workflows=#{workflow1.id}" }
  let(:workflow2) { tenant1_workflows[0] }
  let(:wf2_tag)   { "/approval/workflows=#{workflow2.id}" }
  let(:workflow3) { create(:workflow, :tenant => tenant2) }
  let(:wf3_tag)   { "/approval/workflows=#{workflow3.id}" }

  let!(:tag_link1) { create(:tag_link, :tenant => tenant1, :app_name => 'catalog', :object_type => 'Portfolio', :tag_name => wf1_tag, :workflow => workflow1) }
  let!(:tag_link2) { create(:tag_link, :tenant => tenant1, :app_name => 'topology', :object_type => 'ServiceInventory', :tag_name => wf2_tag, :workflow => workflow2) }
  let!(:tag_link3) { create(:tag_link, :tenant => tenant1, :app_name => 'catalog', :object_type => 'Portfolio', :tag_name => wf2_tag, :workflow => workflow2) }
  let!(:tag_link4) { create(:tag_link, :tenant => tenant2, :app_name => 'catalog', :object_type => 'Portfolio', :tag_name => wf3_tag, :workflow => workflow3) }

  let(:tag1) do
    { :tag => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=#{workflow1.id}" }
  end

  let(:tag2) do
    { :tag => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=#{workflow2.id}" }
  end

  let(:tag3) do
    { :tag => "/#{WorkflowLinkService::TAG_NAMESPACE}/#{WorkflowLinkService::TAG_NAME}=#{workflow3.id}" }
  end

  let(:bogus_tag) do
    { :tag => '/curious/george=gnocchi' }
  end

  let(:tag_resource1) do
    { 'app_name'    => 'catalog',
      'object_type' => 'Portfolio',
      'tags'        => [tag1, tag2] }
  end

  let(:tag_resource2) do
    { 'app_name'    => 'topology',
      'object_type' => 'ServiceInventory',
      'tags'        => [tag1, tag2] }
  end

  let(:tagless_resource) do
    { 'app_name'    => 'topology',
      'object_type' => 'ServiceInventory',
      'tags'        => [] }
  end

  let(:mismatch_tag_resource) do
    { 'app_name'    => 'catalog',
      'object_type' => 'Portfolio',
      'tags'        => [bogus_tag] }
  end
end
