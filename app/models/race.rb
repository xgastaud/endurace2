class Race < ApplicationRecord
  include PgSearch
  multisearchable against: [ :name, :sport, :format, :address ]
  has_many :participations, dependent: :destroy
  has_many :reviews, dependent: :destroy
  mount_uploader :photo, PhotoUploader
  validates :address, presence: true
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?
  FORMATS_SPORTS = {
    "Triathlon" => ["Triathlon"],
    "Running" => ["Marathon", "Semi-marathon", "Course de 15km ou moins"]
    # "Cyclisme" => ["Autre"],
    # "Swimrun" => "Long",
  }

  validates :sport, inclusion: { in: FORMATS_SPORTS.keys, allow_blank: false }
  validate :format_consistent_with_sport
  acts_as_votable

  def format_consistent_with_sport
    if !(FORMATS_SPORTS[self.sport] || []).include?(self.format)
      errors.add(:format, "is not included in the list")
    end
  end

  def voters_excluding_self(user)
    get_likes.reject { |like| like.voter == user }.map {|like| like.voter }
  end

  def average_rating
    sum = 0
    reviews.each do |review|
      sum += review.score unless review.score.nil?
    end
    reviews.count == 0 ? 0 : sum.fdiv(reviews.count).to_i
  end
end
