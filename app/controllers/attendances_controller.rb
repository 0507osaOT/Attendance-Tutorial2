class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :show]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :require_login # ログインしていないユーザーはアクセスできないようにする

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  # 出勤・退勤登録ボタン押下時の処理
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
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

  # 勤怠編集ページの表示
  def edit_one_month
    @user = User.find(params[:id])
    @superiors = User.where(superior: true)
    @current_user = current_user # ログインしている上長
    @superiors = User.where(superior: true).where.not(id: @current_user.id) # ログイン中の上長を除外
    @attendances = Attendance.all
    @first_day = params[:date].to_date
    @last_day = @first_day.end_of_month
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
  end

  #勤怠編集ページの”編集を保存する”ボタン押下時の処理
  def update_one_month
    ActiveRecord::Base.transaction do
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        @attendance = attendance
  
        # 指示者確認印が選択されている場合のみ処理を行う
        next unless item[:work_instructor].present?
  
        # 出社時間と退社時間の両方が入力されている場合
        if item[:started_at].present? && item[:finished_at].present?
          # 退社時間が出社時間以前の場合はエラーを返して処理を終了する
          if item[:finished_at] <= item[:started_at]
            flash[:danger] = "退社時間は出社時間より遅い時間を入力してください。"
            redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
          else
            # 当日以降の勤怠は更新しない
            unless attendance.worked_on > Date.today
              # 勤怠変更情報を一時保存する
              attendance.chg_started_at = item[:started_at]
              attendance.chg_finished_at = item[:finished_at]
              attendance.note = item[:note]
              attendance.work_instructor = item[:work_instructor]
              attendance.work_status = "申請中"
              attendance.save!
            end
          end
        else
          # 出社時間または退社時間のどちらかが入力されていない場合
          flash[:danger] = "出社時間と退社時間の両方を入力してください。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        end
      end
  
      flash[:success] = "勤怠変更を更新しました。"
      redirect_to user_url(date: params[:date])
    rescue ActiveRecord::RecordInvalid => e
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
      flash[:danger] += " #{e.message}" if e.message.present?
      redirect_to attendances_edit_one_month_user_url(date: params[:date])
    end
  end

  #勤怠変更申請　モーダル表示
  def show_change_modal
    @user = User.find(params[:id])
    @attendances = @user.attendances.where(work_status: "申請中").distinct
    @applicants = User.joins(:attendances).where(attendances: {work_status: "申請中", work_instructor: @user.name}).distinct
    @change_req_sum = @attendances.count
  end

  #勤怠変更申請　承認処理
  def update_change_modal
    apply_flg = false
    ActiveRecord::Base.transaction do
      attendance_change_params.each do |id, item|
        if item[:work_approval] == "1"
          attendance = Attendance.find(id)
          case item[:work_status]
          when "承認"
            attendance.before_started_at = attendance.started_at
            attendance.before_finished_at = attendance.finished_at
            attendance.started_at = attendance.chg_started_at
            attendance.finished_at = attendance.chg_finished_at
            attendance.work_status = "承認"
            attendance.work_approval = "true"
            attendance.approval_date = Time.now
            apply_flg = true
          when "否認"
            attendance.work_status = "否認"
            attendance.work_approval = "true"
            apply_flg = true
          else
            # 何もしない
          end
          attendance.save!
        end
      end
    end

    if apply_flg
      flash[:success] = "勤怠変更申請について、指示者確認情報を更新しました。"
    else
      flash[:info] = "変更がありませんでした。"
    end
    redirect_to user_url
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効なデータがあったため、更新をキャンセルしました。"
    redirect_to user_url
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
  
  #残業申請のモーダル表示
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
    else
      flash[:info] = "変更がありませんでした。"
    end
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効なデータがあったため、更新をキャンセルしました。"
    redirect_to user_url(date: params[:date])
  end

  #確認用の勤怠表示(残業申請・所属長承認申請・勤怠変更申請)
  # def show_attendances_status_req
  #   @applicant = User.find(params[:id])
  #   @attendances = @applicant.attendances.where(status: "申請中").distinct
  # end
  
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

  #勤怠修正ログ・変更履歴表示
  def search_log
    @user = User.find(params[:user_id]) # ユーザーを取得
  
    # 承認済みの勤怠情報を取得
    @attendance_logs = Attendance.where(user_id: @user.id).where.not(work_approval: nil)
  
    # 年月の検索パラメータがある場合、絞り込みを行う
    if params[:year].present? && params[:month].present?
      start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
      end_date = start_date.end_of_month
      @attendance_logs = @attendance_logs.where(worked_on: start_date..end_date)
    end
  
    @attendance_logs = @attendance_logs.order(worked_on: :desc)
  end

  def export_csv
    # 受け取った日付パラメータをDate型に変換
    target_date = Date.parse(params[:date])
    if params[:user_id].present?
      @user = User.find(params[:user_id])
      @attendances = @user.attendances.where(worked_on: target_date.beginning_of_month..target_date.end_of_month)
    else
      @attendances = Attendance.where(worked_on: target_date.beginning_of_month..target_date.end_of_month)
    end
    # 曜日の配列を定義
    youbi = %w[日 月 火 水 木 金 土]
    # CSVデータの生成
    csv_data = CSV.generate do |csv|
      # ヘッダー行
      csv << ['日付', '曜日', '出社時間', '退社時間']
      
      # データ行
    @attendances.each do |attendance|
      # 出社/退社時間の処理
      start_time = '--:--'
      if attendance.started_at.present?
        start_time = attendance.started_at.strftime('%H:%M')
      end

      end_time = '--:--'  
      if attendance.finished_at.present?
        end_time = attendance.finished_at.strftime('%H:%M')
      end

      csv << [
        attendance.worked_on.strftime('%-m/%-d'),
        youbi[attendance.worked_on.wday],
        start_time,
        end_time
      ]
    end
    end

    # CSVファイルとしてダウンロード
    timestamp = Time.current.strftime('%Y%m%d')
    send_data csv_data,
              filename: "attendance_#{timestamp}.csv",
              type: 'text/csv',
              charset: 'shift_jis'
  end

  private
  def show_monthly_attendances_modal_params
    params.require(:user).permit(monthly_attendances: [:master_status,:approval])[:monthly_attendances]
  end

  def attendances_params
    params.require(:user).permit(attendances: [:started_at, :finished_at, :note, :work_instructor, :work_approval, :chg_started_at, :chg_finished_at])[:attendances]
  end  

  def attendance_change_params
    params.require(:user).permit(attendances: [:work_status, :work_approval])[:attendances]
  end

  def overtime_application_params
    params.require(:user).permit(attendances: [:status, :approval])[:attendances]
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