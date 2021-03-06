require_relative 'mixins/group_validate_mixin'

class WorkflowUpdateService
  include GroupValidateMixin
  attr_accessor :workflow_id

  def initialize(workflow_id)
    self.workflow_id = workflow_id
  end

  def update(options)
    if options[:group_refs]
      options[:group_refs] = validate_approver_groups(options[:group_refs])
    end

    Workflow.find(workflow_id).update!(options)
  end
end
