class Subscription < ApplicationRecord
  belongs_to :subscriber
  belongs_to :subscriber_list

  enum frequency: { immediately: 0, daily: 1, weekly: 2 }

  before_validation :set_uuid

  validates :subscriber, uniqueness: { scope: :subscriber_list }

  scope :not_deleted, -> { where(deleted_at: nil) }

  def destroy
    update_attributes!(deleted_at: Time.now)
  end

private

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
