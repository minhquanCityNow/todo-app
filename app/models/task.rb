class Task < ApplicationRecord
  after_initialize :set_defaults
  after_create_commit { TaskBroadcastJob.perform_later self }
  enum status: { backlog: 'backlog', inprocess: 'inprocess', complete: 'complete' }
  validates_presence_of :title, :content, presence: true

  def set_defaults
    self.status = "backlog" if self.new_record?
  end
end
