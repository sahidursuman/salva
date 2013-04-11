class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  extend LDAP::Helpers::UserModel
  extend Aleph::Helpers::UserModel

  if ldap_enabled?
    devise :ldap_authenticatable, :timeoutable, :lockable
  else
    # Uncomment this line if you are using a new database
    # devise :database_authenticatable, :timeoutable, :lockable

    # Comment this line if uncomment the previous line, it is useful for users with previous versions of salva
    devise :database_authenticatable, :timeoutable, :lockable, :encryptable, :encryptor => :salva_sha512, :stretches => 40

    # Uncomment the following line If you want to enable the email
    # attribute for modifications in systems without ldap support.
    # attr_accessible :email
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessor :current_password

  #RMO :professional_address instead of :address
  attr_accessible :password, :password_confirmation, :remember_me, :user_identifications_attributes,
                  :person_attributes, :professional_address_attributes, :jobposition_attributes, :current_password,
                  :jobposition_log_attributes, :user_schoolarships_attributes, :documents_attributes,
                  :author_name, :blog, :homepage, :calendar, :user_cite_attributes,
                  :homepage_resume, :homepage_resume_en

  scope :activated, where(:userstatus_id => 2)
  scope :inactive, where('userstatus_id != 2')
  scope :postdoctoral, joins(:jobposition, :user_adscriptions).where("jobpositions.jobpositioncategory_id = 38  AND user_adscriptions.jobposition_id = jobpositions.id")
  scope :not_in_postdoctoral, joins(:jobposition, :user_adscriptions).where("jobpositions.jobpositioncategory_id != 38  AND user_adscriptions.jobposition_id = jobpositions.id")
  scope :fullname_asc, joins(:person).order('people.lastname1 ASC, people.lastname2 ASC, people.firstname ASC')
  scope :fullname_desc, joins(:person).order('people.lastname1 DESC, people.lastname2 DESC, people.firstname DESC')
  scope :distinct, select("DISTINCT (users.*)")
  scope :researchers, :conditions => "(jobpositioncategories.roleinjobposition_id = 1 OR jobpositioncategories.roleinjobposition_id = 110)", :include => { :jobpositions => :jobpositioncategory}
  scope :academic_technicians, :conditions => "jobpositioncategories.roleinjobposition_id = 3 AND (jobpositioncategories.roleinjobposition_id != 1 OR jobpositioncategories.roleinjobposition_id != 110 OR jobpositioncategories.roleinjobposition_id != 4 OR jobpositioncategories.roleinjobposition_id != 5)", :include => { :jobpositions => :jobpositioncategory}
  scope :posdoctorals, :conditions => "jobpositioncategories.roleinjobposition_id = 111", :include => { :jobpositions => :jobpositioncategory}

  # :userstatus_id_equals => find_all_by_userstatus_id
  scope :fullname_like, lambda { |fullname| 
    sql = " users.id IN (#{Person.user_id_by_fullname_like(fullname).to_sql}) "
    where sql
  }

  scope :adscription_id_equals, lambda { |adscription_id| joins(:user_adscriptions).where(["user_adscriptions.adscription_id = ?", adscription_id] ) }
  scope :schoolarship_id_equals, lambda { |schoolarship_id| joins(:user_schoolarships).where(["user_schoolarships.schoolarship_id = ?", schoolarship_id] ) }
  scope :annual_report_year_equals, lambda { |year| includes(:documents).where(["documents.documenttype_id = 1 AND documents.title = ?", year]) }

  scope :jobposition_start_date_year_equals, lambda { |year|
    sql = " users.id IN (#{Jobposition.user_id_by_start_date_year(year).to_sql}) "
    where sql
  }

  scope :jobposition_end_date_year_equals, lambda { |year|
    sql = " users.id IN (#{Jobposition.user_id_by_end_date_year(year).to_sql}) "
    where sql
  }

  scope :jobpositioncategory_id_equals, lambda { |jobpositioncategory_id| joins(:jobpositions).where(["jobpositions.jobpositioncategory_id = ?", jobpositioncategory_id]) }

  search_methods :fullname_like, :adscription_id_equals, :schoolarship_id_equals, :annual_report_year_equals, 
                 :jobposition_start_date_year_equals, :jobposition_end_date_year_equals, :jobpositioncategory_id_equals,
                 :login_like

  belongs_to :userstatus

  belongs_to :user_incharge, :class_name => 'User', :foreign_key => 'user_incharge_id'
  belongs_to :registered_by, :class_name => 'User', :foreign_key => 'registered_by_id'
  belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'

  has_one :person
  has_one :user_group
  has_many :addresses
  has_one :address, :class_name => "Address",  :conditions => "addresses.addresstype_id = 1 "
  has_one :professional_address, :class_name => "Address",  :conditions => "addresses.addresstype_id = 1 "
  has_one :jobposition, :order => 'jobpositions.start_date DESC, jobpositions.end_date DESC'
  has_one :most_recent_jobposition, :class_name => "Jobposition", :include => :institution,
          :conditions => "(institutions.institution_id = 1 OR institutions.id = 1) AND jobpositions.institution_id = institutions.id ",
          :order => "jobpositions.start_date DESC"
  #RMO change "jobpositioncategories.jobpositiontype_id  = 1" to "jobpositioncategories.jobpositiontype_id  <= 2" to include personal for teaching activities.
  #RMO Avoid errors in HomePages
  has_one :jobposition_for_researching, :class_name => "Jobposition", :include => [:institution, :jobpositioncategory],
          :conditions => "(institutions.institution_id = 1 OR institutions.id = 1) AND jobpositions.institution_id = institutions.id AND jobpositioncategories.jobpositiontype_id <= 2",
          :order => "jobpositions.start_date DESC"

  has_one :user_identification
  has_one :user_schoolarship
  has_one :user_cite
  has_one :jobposition_log
  has_one :session_preference

  has_many :user_adscriptions
  has_many :jobpositions
  has_one  :user_adscription, :include => :jobposition, :order => 'user_adscriptions.start_date DESC, user_adscriptions.end_date DESC'
  has_one  :jobposition_as_postdoctoral, :class_name => 'Jobposition', :conditions => 'jobpositions.jobpositioncategory_id = 38', :order => 'jobpositions.start_date DESC, jobpositions.end_date DESC'
  has_one  :user_adscription_as_postdoctoral, :class_name => 'UserAdscription', :conditions => 'jobpositions.jobpositioncategory_id = 38 and user_adscriptions.jobposition_id = jobpositions.id', :include => :jobposition, :order => 'user_adscriptions.start_date DESC, user_adscriptions.end_date DESC'
  has_many :user_schoolarships, :order => 'user_schoolarships.start_date DESC, user_schoolarships.end_date DESC'
  has_many :user_schoolarships_as_posdoctoral, :conditions => "user_schoolarships.schoolarship_id >=48  AND user_schoolarships.schoolarship_id <= 53", :order => 'user_schoolarships.start_date DESC, user_schoolarships.end_date DESC', :class_name => 'UserSchoolarship'
  has_many :documents
  has_many :user_identifications

  has_many :user_researchlines
  has_many :researchlines, :through => :user_researchlines, :order => 'researchlines.name ASC', :limit => 10
  has_many :user_skills

  has_many :user_articles, :include => :articles
  has_many :articles, :through => :user_articles
  has_many :published_articles, :through => :user_articles, :source => :article,
           :conditions => 'articles.articlestatus_id = 3',
           :order => 'articles.year DESC, articles.month DESC, articles.authors ASC, articles.title ASC'
  has_many :recent_published_articles, :through => :user_articles, :source => :article,
           :conditions => 'articles.articlestatus_id = 3',
           :order => 'articles.year DESC, articles.month DESC, articles.authors ASC, articles.title ASC', :limit => 5

   has_many :inprogress_articles, :through => :user_articles, :source => :article,
           :conditions => 'articles.articlestatus_id != 3',
           :order => 'articles.year DESC, articles.month DESC, articles.authors ASC, articles.title ASC'

  has_many :user_theses
  has_many :theses, :through => :user_theses

  #Added for use in home_pages
  has_many :recent_advised_theses, :through => :user_theses, :source => :thesis,
           :conditions => 'theses.thesisstatus_id = 3 and user_theses.roleinthesis_id > 1',
           :order => 'theses.end_date DESC, theses.authors ASC, theses.title ASC', :limit => 5

  #Added for use in home_pages
  has_many :recent_published_books, :through => :bookedition_roleinbooks, :source => :bookedition,
           :conditions => 'bookedition_roleinbooks.roleinbook_id = 1',
           :order => 'bookeditions.year DESC, bookeditions.month DESC', :limit => 5

  #Added for use in home_pages
  has_many :recent_book_chapters, :through => :chapterinbook, :source => :bookedition,
           :conditions => 'chapterinbook_roleinchapters.roleinchapter_id = 1',
           :order => 'bookeditions.year DESC, bookeditions.month DESC', :limit => 5

  #Added for use in home_pages
  has_many :bookedition_roleinbooks
  has_many :chapterinbook_roleinchapters
  has_many :chapterinbook, :through => :chapterinbook_roleinchapters





  #RMO :professional_address intead of :address
  accepts_nested_attributes_for :person, :professional_address, :jobposition, :user_group, :user_schoolarships, :documents, :user_schoolarship
  accepts_nested_attributes_for :user_identifications, :allow_destroy => true
  accepts_nested_attributes_for :user_cite
  

  def self.paginated_search(options={})
    search(options[:search]).page(options[:page] || 1).per(options[:per_page] || 10)
  end

  def self.login_like(login)
    login_sql = "%#{login.downcase}%"
    @users = where("users.login LIKE ?", login_sql)
    @users += ldap_users_like(login) if ldap_enabled?
    users
  end

  def author_name
    if !super.to_s.strip.empty?
      super
    elsif !user_cite.nil? and !user_cite.author_name.to_s.strip.empty?
      user_cite.author_name
    elsif !person.nil?
      person.shortname
    end
  end

  def fullname_or_login
     has_person? ? person.fullname : login
  end


  def fullname_or_email
     has_person? ? person.fullname : email
  end
  alias :name :fullname_or_email


  def firstname_and_lastname
     has_person? ? person.firstname_and_lastname : email
  end

  def has_person?
    !person.nil? and !person.id.nil?
  end

  def friendly_email
    "#{fullname_or_email} <#{email}>"
  end

  def user_incharge_fullname
    user_incharge.fullname_or_login unless user_incharge.nil?
  end

  def fullname_of_registered_by
    registered_by.fullname_or_login unless registered_by.nil?
  end

  def adscription_name
    user_adscription.adscription.name if has_adscription?
  end

  def adscription_abbrev
    user_adscription.adscription.abbrev if has_adscription?
  end

  def adscription_id
    user_adscription.adscription.id if has_adscription?
  end

  def has_adscription?
    !user_adscription.nil?
  end

  def category_name
    jobposition.category_name unless jobposition.nil?
  end

  def has_image?
    !person.nil? and !person.image.nil?
  end

  def avatar(version=:icon)
    if !person.nil? and !person.image.nil?
      person.image.file.url(version.to_sym)
    else
      "/images/avatar_missing_#{version}.png"
    end
  end

  def update_password(attr)
    if User.ldap_enabled?
      new_password_valid?(attr) and update_ldap_password(attr)
    else
      new_password_valid?(attr) and update_with_password(attr)
    end
  end

  def new_password_valid?(attr)
    if !attr[:password].blank? and !attr[:password_confirmation].blank? and attr[:password] == attr[:password_confirmation]
      true
    else
      errors.add(:password, :confirmation)
      false
    end
  end

  def update_ldap_password(attr)
    if valid_ldap_authentication?(attr[:current_password])
      update_attributes(attr)
    else
      errors.add(:current_password, :invalid)
      false
    end
  end

  def group_name
    user_group.group.name if has_group?
  end

  def has_group?
    !user_group.nil?
  end

  def admin?
    group_name == 'admin'
  end

  def worker_key
    jobposition_log.nil? ? email : jobposition_log.worker_key
  end

  def worker_number
    jobposition_log.worker_number || ''
  end
end
