class Workflow < ApplicationRecord
  include Metadata
  acts_as_tenant(:tenant)

  default_scope { order(:sequence => :asc) }

  belongs_to :template
  before_destroy :validate_deletable, :prepend => true
  has_many :requests, -> { order(:id => :asc) }, :inverse_of => :workflow, :dependent => :nullify
  has_many :tag_links, :dependent => :destroy, :inverse_of => :workflow

  validates :name, :presence => true, :uniqueness => {:scope => :tenant}
  validates :sequence, :uniqueness => {:scope => :tenant_id}

  before_validation :new_sequence, :on => :create
  before_validation :adjust_sequences, :on => :update
  after_save        :validate_positive_sequences
  before_destroy    :sequence_lower
  after_destroy     :validate_positive_sequences

  def external_processing?
    template&.process_setting.present?
  end

  def external_signal?
    template&.signal_setting.present?
  end

  def metadata
    super.merge(:object_dependencies => object_dependencies)
  end

  def deletable?
    requests.any? { |request| !request.finished? } ? false : true
  end

  private

  def validate_deletable
    throw :abort unless deletable?
  end

  def object_dependencies
    {}.tap do |dependencies|
      tag_links.pluck(:app_name, :object_type).uniq.each do |key, value|
        dependencies[key] ||= []
        dependencies[key] << value
      end
    end
  end

  def table
    self.class.arel_table
  end

  def new_sequence
    throw :abort if sequence && sequence <= 0

    largest = last_sequence
    if sequence && sequence < last_sequence
      sequence_higher(sequence)
    else
      self.sequence = largest + 1 # auto_assignment if sequence is nil or too large
    end
  end

  # no gap between sequences
  def adjust_sequences
    return unless sequence_changed?

    throw :abort if sequence && sequence <= 0

    largest = last_sequence
    self.sequence = largest if sequence.nil? || sequence > largest

    return if sequence == sequence_was
    
    if sequence > sequence_was
      sequence_lower(sequence_was, sequence)
    else
      sequence_higher(sequence, sequence_was)
    end
  end

  # sequences increment between [sequence sequence_was sequence)
  def sequence_higher(startp, endp = nil)
    change_sequences_to_negative(startp, endp, -1)
    change_sequences_to_positive(endp ? -endp - 1 : nil)
  end

  # sequences decrement between [startp endp]
  def sequence_lower(startp = sequence, endp = nil)
    change_sequences_to_negative(startp, endp, 1)
    change_sequences_to_positive(-startp + 1)
  end

  def change_sequences_to_negative(startp, endp, delta)
    query = self.class.reorder(:id).where(table[:sequence].gteq(startp))
    query = query.where(table[:sequence].lteq(endp)) if endp
    query.update_all(["sequence = (-sequence + (?))", delta])
  end

  def change_sequences_to_positive(exceptp)
    query = self.class.reorder(:id).where(table[:sequence].lt(0))
    query = query.where.not(:sequence => exceptp) if exceptp
    query.update_all("sequence = (-sequence)")
  end

  def last_sequence
    self.class.last&.sequence.to_i
  end

  def validate_positive_sequences
    raise Exceptions::NegativeSequence, "Internal error caused by concurrency. Please try again" if self.class.where(table[:sequence].lteq(0)).exists?
  end
end
