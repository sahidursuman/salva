class Newspaperarticle < ActiveRecord::Base
  validates_presence_of :title, :authors, :newspaper_id, :newsdate

  validates_numericality_of :id, :allow_nil => true, :greater_than =>0, :only_integer => true
  validates_numericality_of :newspaper_id, :greater_than =>0, :only_integer => true

  belongs_to :newspaper
  belongs_to :registered_by, :class_name => 'User'
  belongs_to :modified_by, :class_name => 'User'

  has_many :user_newspaperarticles
  has_many :users, :through => :user_newspaperarticles
  accepts_nested_attributes_for :user_newspaperarticles

  default_scope :order => 'newsdate DESC, authors ASC, title ASC'

  scope :user_id_eq, lambda { |user_id| joins(:user_newspaperarticles).where(:user_newspaperarticles => {:user_id => user_id}) }
  scope :user_id_not_eq, lambda { |user_id|  where("newspaperarticles.id IN (#{UserNewspaperarticle.select('DISTINCT(newspaperarticle_id) as newspaperarticle_id').where(["user_newspaperarticles.user_id !=  ?", user_id]).to_sql}) AND newspaperarticles.id  NOT IN (#{UserNewspaperarticle.select('DISTINCT(newspaperarticle_id) as newspaperarticle_id').where(["user_newspaperarticles.user_id =  ?", user_id]).to_sql})") }
  scope :year_eq, lambda {|year| by_year(year, :field => :newsdate) }

  search_methods :user_id_eq, :user_id_not_eq, :year_eq

  def as_text
    [authors, title, newspaper.name_and_country, pages, I18n.localize(newsdate, :format => :long_without_day) ].compact.join(', ')
  end

  def has_associated_users?
     users.size > 0
  end

  def has_association_with_user?(user_id)
     !user_newspaperarticles.where(:user_id => user_id).first.nil?
  end
end
