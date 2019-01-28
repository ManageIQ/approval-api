class User < ApplicationRecord
  acts_as_tenant(:tenant)

  has_many :usergroups, :dependent => :destroy
  has_many :groups, -> { order(:id => :asc) }, :through => :usergroups
  validates :email, :presence => true

  def stages
    groups.collect(&:stages).compact.flatten.uniq.sort_by(&:id)
  end

  def requests
    Request.find(stages.map(&:request_id)).sort_by(&:id)
  end
end
