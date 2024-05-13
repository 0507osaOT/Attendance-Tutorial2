class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :show]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :require_login # ログインしていないユーザーはアクセスできないようにする

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    puts "Params ID: #{params[:id]}" # デバッグ用の出力
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
  end

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

  def new_overtime_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find_by(worked_on: params[:date])
    @overtime_request = OvertimeRequest.new
  end

  def create_overtime_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find_by(worked_on: params[:date])
    @overtime_request = OvertimeRequest.new(overtime_request_params)

    if @overtime_request.save
      flash[:success] = "残業申請が送信されました。"
      redirect_to user_path(@user, date: @attendance.worked_on)
    else
      render 'overtime_request'
    end
  end

  def edit_overtime_application_req
    @user = User.find(params[:id])
    #@attendance = Attendance.find_by(worked_on: params[:date])
    @attendance = @user.attendances.find_by(worked_on: params[:date])
    @date = params[:date].to_date
    @superiors = User.where(superior: true).where.not(name: @user.name)
  end

  def update_overtime_application_req
    
    @user = User.find(params[:id])
    @attendance = Attendance.find_by(worked_on: params[:attendance][:date]&.to_date, user_id: @user.id)
  
    if @attendance
      # Update attendance with overtime information
      @attendance.update(
        overtime: params[:attendance][:overtime],  # "overtime_at" ではなく "overtime" を使用
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

  def show_monthly_attendances_modal
    @user = User.find(params[:id])
    @monthly_attendances = User.joins(:monthly_attendances).where(monthly_attendances: {master_status: "申請中", instructor:@user.name}).distinct
  end

  def update_monthly_attendances_modal
    # アクションの処理を記述
  end

  def _head_of_department_approval_modal
    @user = User.find(params[:id])
    @attendances = @user.attendances.where(status: "申請中").distinct
  end

  def show_change_modal
    @user = User.find(params[:id])
    @attendances = @user.attendances.where(status: "申請中").distinct
  end

  def show_overtime_modal
    @user = User.find(params[:id])
    @applicants = User.joins(:attendances).where(attendances: {status: "申請中", overtime_instructor: @user.name}).distinct
  end

  # 残業申請の承認処理
  def update_overtime_modal
    # 承認情報更新フラグ
    apply_flg = false

    ActiveRecord::Base.transaction do   # トランザクションを開始します。
      # 残業申請の承認処理
      overtime_application_params.each do |id, item|
        #　checkboxにチェックあり？
        if item[:approval] == "1"

          overtime_attendance = Attendance.find(id)

          case item[:status]
          when "承認"   # 承認
            overtime_attendance.status = "承認"
            overtime_attendance.approval = true
            apply_flg = true

          when "否認", "なし"    # 否認、なし
            overtime_attendance.status = item[:status]
            overtime_attendance.approval = true
            apply_flg = true

          else
            # 何もしない
          end

          # DBへ更新情報を記録
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

  def send_monthly_attendance_request
    #byebug
    @user = User.find(params[:id])
    @date = params[:user][:date].presence || Date.current # params[:date]がnilの場合は、現在の日付を使用する
    @month = @date.to_date.month
    @year = @date.to_date.year
    monthly_attendance = MonthlyAttendance.find_or_create_by(user_id: @user.id, month: @month, year: @year)
    
    if monthly_attendance.persisted?
      #申請先の上長
      monthly_attendance.instructor = params[:user][:approval_instructor]
      #申請ステータス
      monthly_attendance.master_status = "申請中"
      monthly_attendance.save
      flash[:success] = "1ヶ月分の勤怠申請を送信しました。"
    else
      flash[:danger] = "1ヶ月の勤怠申請に失敗しました。"
    end
    
    redirect_to user_url(date: @date)
  end
  

  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    # 残業申請の承認情報を扱います。
    def overtime_application_params
      params.require(:user).permit(attendances: [:status,:approval])[:attendances]
    end

    # 管理権限者、または現在ログインしているユーザーを許可します。
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
        redirect_to login_url # halts request cycle
      end
    end
end