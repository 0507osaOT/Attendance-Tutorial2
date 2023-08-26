class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_user]
  before_action :correct_user, only: [:edit]
  before_action :admin_or_correct_user, only: [:update]
  before_action :admin_user, only: [:destroy, :edit_basic_info, :update_basic_info]
  before_action :set_one_month, only: [:show]
  before_action :user_admin, only: [:index]
  #before_action :check_user_authorization, only: [:index, :show]
  
    # システム管理権限所有かどうか判定します。
  def index
    @users = User.all
    @users = @users.where('name LIKE ?', "%#{params[:search]}%") if params[:search].present?
    @users = @users.paginate(page: params[:page], per_page: 20)  # 20件ずつ表示（調整可）
  end
  
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
  
    # ログインユーザーが管理者または自分自身の場合は処理を終了する
    return if current_user.admin? || current_user == @user
    # それ以外の場合は権限エラーメッセージを表示する
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
  # 出勤時間のみ格納されている一般ユーザーを取得する
    @users = User.joins(:attendances).where.not(attendances: { started_at: nil }).where.not(name: "Sample User")
  # 他の処理があればここに追加
  end
  
  def update_attendance
  # ページだけ用意
  end
  
  def correction
  
  end
  
  private

  def users_params
    params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
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
    @users = User.all
      if  current_user.admin == false
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