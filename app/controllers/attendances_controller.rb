class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :show]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :require_login # ログインしていないユーザーはアクセスできないようにする

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  # 出勤・退勤登録ボタン押下時の処理
  def update
    @attendance = Attendance.find(params[:id])
    if @attendance.update(attendance_params)
      flash[:success] = "勤怠情報を更新しました。"
    else
      flash[:danger] = "勤怠情報の更新に失敗しました。"
    end
    redirect_to @user
  end

  # 勤怠編集ページの表示
  def edit_one_month
  end

  #勤怠編集ページの更新ボタン押下時の処理
  def update_one_month
    apply_flg = false  # apply_flg を定義

    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "出社時間と退社時間の両方を入力してください。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        elsif item[:started_at].blank? && item[:finished_at].present?
          flash[:danger] = "出社時間と退社時間の両方を入力してください。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        else
          attendance.update_attributes!(item) unless attendance.worked_on > Date.today #当日以降の勤怠は更新しないようにする
        end
      end

      apply_flg = true # トランザクションが正常に終了した場合にフラグを設定

      flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
      redirect_to user_url(date: params[:date])
    rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
      redirect_to attendances_edit_one_month_user_url(date: params[:date])
    end
  end

  #残業申請ボタン押下・表示
  def edit_overtime_application_req
    @user = User.find(params[:id])
    @attendance = @user.attendances.find_by(worked_on: params[:date])
    @date = params[:date].to_date
    @superiors = User.where(superior: true).where.not(name: @user.name)
  end
  
  #残業申請フォームの内容送信時の処理
  def update_overtime_application_req
    @user = User.find(params[:id])
    @attendance = Attendance.find_by(worked_on: params[:attendance][:date]&.to_date, user_id: @user.id)
    if @attendance
      @attendance.update(
        overtime: params[:attendance][:overtime],
        approval: params[:attendance][:approval],
        overtime_content: params[:attendance][:overtime_content],
        overtime_instructor: params[:attendance][:overtime_instructor],
        status: "申請中")
      flash[:success] = "残業申請を受け付けました。"
      redirect_to user_url
    else
      flash[:danger] = "勤怠データが見つかりません。"
      redirect_to user_url
    end
  end
  
  #残業申請の内容表示
  def show_overtime_modal
    @user = User.find(params[:id])
    @applicants = User.joins(:attendances).where(attendances: {status: "申請中", overtime_instructor: @user.name}).distinct
  end
  
  # 残業申請の承認処理
  def update_overtime_modal
    apply_flg = false
    ActiveRecord::Base.transaction do
      overtime_application_params.each do |id, item|
        if item[:approval] == "1"
          overtime_attendance = Attendance.find(id)
          case item[:status]
          when "承認"
            overtime_attendance.status = "承認"
            overtime_attendance.approval = true
            apply_flg = true
          when "否認", "なし"
            overtime_attendance.status = item[:status]
            overtime_attendance.approval = true
            apply_flg = true
          else
            # 何もしない
          end
          overtime_attendance.save!
        end
      end
    end

    if apply_flg
      flash[:success] = "残業申請について、指示者確認情報を更新しました。"
    end
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効なデータがあったため、更新をキャンセルしました。"
    redirect_to user_url(date: params[:date])
  end

  #確認用の勤怠表示(残業申請・所属長承認申請・勤怠変更申請)
  def show_attendances_status_req
    @applicant = User.find(params[:id])
    @attendances = @applicant.attendances.where(status: "申請中").distinct
    render 'show'
  end
  
  #1ヶ月分の勤怠申請処理
  def send_monthly_attendance_request
    @user = User.find(params[:id])
    @date = params[:user][:date].presence || Date.current
    @month = @date.to_date.month
    @year = @date.to_date.year
    monthly_attendance = MonthlyAttendance.find_or_create_by(user_id: @user.id, month: @month, year: @year)
    if monthly_attendance.persisted?
      monthly_attendance.instructor = params[:user][:approval_instructor]
      monthly_attendance.master_status = "申請中"
      monthly_attendance.save
      flash[:success] = "1ヶ月分の勤怠申請を送信しました。"
    else
      flash[:danger] = "1ヶ月の勤怠申請に失敗しました。"
    end
    redirect_to user_url(date: @date)
  end

  #所属長承認申請　モーダル表示
  def show_monthly_attendances_modal
    @user = User.find(params[:id])
    @applicants = User.joins(:monthly_attendances).where(monthly_attendances: {master_status: "申請中", instructor:@user.name}).distinct
  end
  
  #所属長承認申請　承認処理
  def update_monthly_attendances_modal
    @user = User.find(params[:id])
    apply_flg = false
    
    ActiveRecord::Base.transaction do
      show_monthly_attendances_modal_params.each do |id, item|
        if item[:approval] == "1"
          monthly_attendance = MonthlyAttendance.find(id)
          case item[:master_status]
          when "承認"
            monthly_attendance.master_status = "承認"
            monthly_attendance.approval = true
            apply_flg = true
          when "否認", "なし"
            monthly_attendance.master_status = item[:master_status]
            monthly_attendance.approval = true
            apply_flg = true
          else
            # 何もしない（"申請中"の場合）
          end
          monthly_attendance.save!
        end
      end
    end
  
    if apply_flg
      flash[:success] = "1ヶ月分の勤怠申請について、指示者確認情報を更新しました。"
    else
      flash[:info] = "変更がありませんでした。"
    end
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効なデータがあったため、更新をキャンセルしました。"
    redirect_to user_url(date: params[:date])
  end
  
  #勤怠変更申請　モーダル表示
  def show_change_modal
    @user = User.find(params[:id])
    @attendances = @user.attendances.where(status: "申請中").distinct
  end

  #勤怠変更申請　承認処理
  def update_change_modal
  end

  private
  def show_monthly_attendances_modal_params
    params.require(:user).permit(monthly_attendances: [:master_status,:approval])[:monthly_attendances]
  end

  def attendances_params
    params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:approval]
  end

  def overtime_application_params
    params.require(:user).permit(attendances: [:status, :approval])[:attendances]
  end

  def attendance_params
    params.require(:attendance).permit(:started_at, :finished_at)
  end

  def admin_or_correct_user
    @user = User.find(params[:user_id]) if @user.blank?
    unless current_user?(@user) || current_user.admin?
      flash[:danger] = "編集権限がありません。"
      redirect_to(root_url)
    end
  end

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access this section"
      redirect_to login_url
    end
  end
end