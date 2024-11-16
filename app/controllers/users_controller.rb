class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :show_attendances_status_req]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_user, ]
  before_action :correct_user, only: [:edit]
  before_action :admin_or_correct_user, only: [:update]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info]
  before_action :set_one_month, only: [:show, :show_attendances_status_req]
  before_action :check_admin, only: [:update_attendance, :users, :attendance_at_work, :index, :import]

    # システム管理権限所有かどうか判定します。
  def index
      # 基本のユーザー取得
      @users = User.all
    
      # 検索クエリがある場合はフィルタリング
      if params[:search].present?
        search_term = params[:search].downcase
        @users = @users.where('LOWER(name) LIKE ?', "%#{search_term}%")
      end
    
      # ページネーションの適用
      @users = @users.paginate(page: params[:page], per_page: 20)
    rescue
      flash.now[:danger] = "検索でエラーが発生しました。"
      @users = User.paginate(page: params[:page], per_page: 20)
  end
    

  def show
    @user = User.find(params[:id])
  
  # 管理者の場合はアクセス不可
  if current_user.admin?
    
    redirect_to(root_url) and return
  end

  # 上長または本人以外はアクセス不可
  unless current_user.superior? || current_user == @user
    flash[:danger] = "権限がありません"
    redirect_to(root_url) and return
  end
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day)
    @worked_sum = @attendances.where.not(started_at: nil).count
    @attendance_chg_req_sum = Attendance.where(status: "申請中", overtime_instructor: @user.name).count
    @approval_req_sum = MonthlyAttendance.where(master_status: "申請中", instructor: @user.name).count
    @change_req_sum = Attendance.where(work_status: "申請中", work_instructor: @user.name).count
    @superiors = User.where(superior: true)
    @target_month = Date.current.month
    month = @first_day.month.to_s
    year  = @first_day.year.to_s
    @monthly_attendance = @user.monthly_attendances.where(month: month, year: year)

    return if current_user.admin? || current_user == @user
    flash[:danger] = "権限がありません"
    redirect_to(root_url)
  end


  def new
    @user = User.new
  end

  def create
    @user = User.new(users_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
    @user =User.find(params[:id])
  end

  def update
      @user = User.find(params[:id])  # ユーザーのインスタンスを取得
      @attendance = @user.attendances.find_by(id: params[:attendance_id])  # ユーザーの出勤情報のインスタンスを取得
      
      if @user.update(users_params)
        flash[:success] = "ユーザー情報を更新しました"
        
        if current_user.admin?  #管理者の場合
           redirect_to users_url
        else
           redirect_to @user
        end
      
      else
         if current_user.admin?  #管理者の場合
           redirect_to users_url
         else
           render :edit
         end
      end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
    @user = User.find(params[:id])
  end

  def edit_one_month
  end
  
  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  def import
    if params[:file].present?
      User.import(params[:file])
      flash[:success] = "CSVファイルのインポートが完了しました。"
    else
      flash[:danger] = "CSVファイルを選択してください。"
    end
    redirect_to users_url
  end
  
  def attendance_at_work
    today = Date.current  # または Date.today
    @users = User.joins(:attendances)
      .where(attendances: { worked_on: today })        # ① 今日の日付
      .where.not(attendances: { started_at: nil })    # ② 出勤済み
      .where(attendances: { finished_at: nil })       # ③ 未退勤
      .where.not(name: "Sample User")                 # Sample User以外
  end
  
  def update_attendance
  # ページだけ用意
  end
  
  def correction
  
  end

  def show_attendances_status_req
    @worked_sum = @attendances.where.not(started_at: nil).count
    @attendance_chg_req_sum = Attendance.where(status: "申請中",overtime_instructor: @user.name).count

  end

  def check_admin
    unless current_user&.admin?      # もし現在のユーザーが管理者でなければ
      flash[:alert] = "管理者権限が必要です"  # エラーメッセージを設定
      redirect_to root_path          # トップページに強制的に移動させる
    end
  end
  
  private

  def users_params
    params.require(:user).permit(:name, :email, :department, :employee_number, :uid, :password, :password_confirmation)
  end

  def basic_info_params
    params.require(:user).permit(:department, :basic_time, :work_time)
  end
  
  def attendances_params
    params.require(:user).permit(attendances: [:started_at, :finished_at])[:attendances]
  end
  
  def basic_work_time
    @a_finish_at -= @a_start_at 
  end
  
  def logged_in_user
     unless logged_in?
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
     end 
  end
  
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end
  
  def user_admin
    @users = User.paginate(page: params[:page], per_page: 20)
    if current_user.admin == false
      redirect_to root_path
    else
      render action: "index"
    end
  end
  
  def check_user_authorization
    user = User.find(params[:id])
    unless current_user.admin || current_user == user
      flash[:alert] = "権限がありません"
     redirect_to(root_url)
    end
  end
end