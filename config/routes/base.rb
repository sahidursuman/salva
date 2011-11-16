Salva::Application.routes.draw do
  devise_for :users

  resource :user_profile, :user_settings, :jobposition_log, :user_curriculum, :password

  user_resources_for :user_languages, :user_skills, :user_schoolarships, :other_activities,
                     :popular_science_activities, :institutional_activities, :other_teaching_activities,
                     :technical_activities, :user_credits, :user_journals, :reviews, :student_advices,
                     :professor_advices, :institutional_advices, :user_stimuli, :memberships, :user_prizes,
                     :educations, :user_regular_courses, :user_refereed_journals, :tutorial_committees,
                     :jobpositions

  publication_resources_for :articles, :unpublished_articles, :popular_science_works, :outreach_works,
                            :other_works,:teaching_products, :technical_reports, :seminaries, :newspaper_articles,
                            :technical_products, :course_attendees, :course_instructors, :conference_attendees,
                            :conference_organizers, :regular_courses, :theses, :thesis_examinations,
                            :book_authors, :book_collaborations, :book_chapters, :conference_talks


  catalog_resources_for :journals, :publishers, :institutions, :languages, :skilltypes,
                        :schoolarships, :credittypes, :newspapers, :careers, :techproducttypes,
                        :stimuluslevels

  resources :states do
    get :list_by_country, :on => :collection
  end

  resources :cities do
    get :list_by_state, :on => :collection
    get :remote_form, :on => :collection
  end

  resources :jobpositioncategories do
     get :filtered_select, :on => :collection
  end

  resources :user_annual_reports do
    get :send_report, :on => :member
  end

  root :to => "user_profiles#show"
end