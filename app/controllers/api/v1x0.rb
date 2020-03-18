module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.0"]
      end
    end
    class ActionsController     < Api::V1::ActionsController; end
    class RequestsController    < Api::V1::RequestsController; end
    class StageactionController < Api::V1::StageactionController; end
    class TemplatesController   < Api::V1::TemplatesController; end
    class WorkflowsController   < Api::V1::WorkflowsController; end
  end
end
