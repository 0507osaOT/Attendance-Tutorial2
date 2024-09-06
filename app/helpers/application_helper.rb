module ApplicationHelper

  # ページごとにタイトルを返す
  def full_title(page_name = "") # メソッドと引数の定義
    base_title = "AttendanceApp" # 基本となるアプリケーション名を変数に代入
    if page_name.empty? # 引数を受け取っているか判定
      base_title # 引数page_nameが空文字の場合はbase_titleのみ返す
    else # 引数page_nameが空文字ではない場合
      page_name + " | " + base_title # 文字列を連結して返す
    end
  end

  # 時間外時間を算出
  def calc_overtime(overtime, endtime)
    # 『終了予定時間』を「時」に単位変換
    h1 = overtime.hour + (overtime.min.to_f / 60)
    # 『指定勤務終了時間』を「時」に単位変換
    h2 = endtime.hour + (endtime.min.to_f / 60)
    
    # 戻り値として『時間外時間』を返す（時間外時間 ＝ 終了予定時間 − 指定勤務終了時間）
    h1 - h2
  end

  def format_basic_info(time)
    time.strftime("%H:%M") if time.present?
  end
end

