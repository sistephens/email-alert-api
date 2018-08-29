class ContentChangesForEmailQuery
  def self.call(email)
    ContentChange.joins(:subscription_contents).where(subscription_contents: {email: email}).distinct
  end
end
