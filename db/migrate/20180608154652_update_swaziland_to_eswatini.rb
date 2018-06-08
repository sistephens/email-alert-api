class UpdateSwazilandToEswatini < ActiveRecord::Migration[5.2]
  def change
    list = SubscriberList.where("title LIKE '%Swaziland%'")

    list.each do |item|
      item.title.sub! 'Swaziland', 'Eswatini'
      item.save!
    end
  end
end
