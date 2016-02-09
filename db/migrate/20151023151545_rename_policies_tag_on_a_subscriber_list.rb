class RenamePoliciesTagOnASubscriberList < ActiveRecord::Migration
  def up
    target_list = SubscriberListQuery.new.find_exact_match_with(
      { policies: ["inspections-of-schools-colleges-and-children-s-services"] }
    ).first

    if target_list.present?
      target_list.tags = {policy: ["inspections-of-schools-colleges-and-children-s-services"]}
      target_list.save!
    end
  end

  def down
    # noop
  end
end