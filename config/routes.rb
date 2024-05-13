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
      #勤怠の基本情報編集
      get 'edit_basic_info'
      patch 'update_basic_info'
      #勤怠編集
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'

      get 'edit_overwork_request'
      patch 'edit_overwork_request_info'
      
       # 勤怠変更申請
       get 'attendances/show_attendance_chg_req'

      get 'attendances/working'
      #残業申請
      get 'attendances/edit_overtime_application_req'
      patch 'attendances/update_overtime_application_req'
      #1ヶ月の勤怠承認
      get 'attendances/show_month_approval_req'


      #”勤怠変更申請者の勤怠確認
      get 'show_attendances_status_req'

      #”勤怠変更申請のお知らせ”のモーダル
      get 'attendances/show_change_modal'

      #”残業申請のお知らせ”のモーダル
      get 'attendances/show_overtime_modal'
      patch 'attendances/update_overtime_modal'

      #”所属長承認申請のお知らせ”のモーダル
      get 'attendances/_head_of_department_approval_modal'
      patch 'attendances/update_monthly_attendances_modal'
      
      #1ヶ月分の勤怠申請
      patch 'attendances/send_monthly_attendance_request'


    end
    resources :attendances do
      member do
        patch 'update_overtime_application_req'
      end
    end
    # 申請された上長ユーザー画面
    get 'attendances/edit_overtime_application_req'
    patch 'attendances/edit_overtime_applied_req'
    resources :attendances, only: :update
    resources :searches, only: :index
  end
end