Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'
  patch  '/login', to: 'users#edit'


  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
  # 以下の行を追加
  resources :bases

  # get  '/user_attendances', to: 'attendances#update'
  get '/attendance_at_work', to: 'users#attendance_at_work'
  get '/update_attendance', to: 'users#update_attendance'
  #get '/correction', to: 'users#correction'
  get '/index', to: 'bases#index'
  

  resources :users do
    collection {post :import}
  
    member do
      get 'edit_overwork_request'
      patch 'edit_overwork_request_info'
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month' # この行が追加対象です。
      get 'attendances/working'
    end
    resources :attendances, only: :update
    resources :searches, only: :index
  end
end