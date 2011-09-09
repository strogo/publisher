class Edition
  include Mongoid::Document

  include Workflow

  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }
  field :overview, :type => String
  field :alternative_title, :type => String

  class << self; attr_accessor :fields_to_clone end
  @fields_to_clone = []

  validate :not_editing_published_item

  alias_method :admin_list_title, :title

  def not_editing_published_item
    errors.add(:base, "Published editions can't be edited") if changed? and is_published?
  end

  def calculate_statuses
    self.container.calculate_statuses
  end

  def build_clone
    new_edition = self.container.build_edition(self.title)

    self.class.fields_to_clone.each do |attr|
      new_edition.send("#{attr}=", self.send(attr))
    end

    new_edition
  end

  def publish(edition,notes)
    self.container.publish(edition,notes)
  end

  def is_published?
    container.publishings.any? { |p| p.version_number == self.version_number }
  end
  
  def created_by
    creation = actions.detect { |a| a.request_type == Action::CREATED || a.request_type == Action::NEW_VERSION }
    creation.requester if creation
  end
  
  def published_by
    publication = actions.detect { |a| a.request_type == Action::PUBLISHED }
    publication.requester if publication
  end

  def unpublish!
    self.container.publishings.detect { |p| p.version_number == self.version_number }.destroy
    self.actions.each do |a| 
      unless a.request_type == Action::NEW_VERSION or a.request_type == Action::CREATED
        a.destroy
      end
    end
    self.container.save
  end
end
