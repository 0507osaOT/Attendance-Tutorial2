class User < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :monthly_attendances, dependent: :destroy
  attr_accessor :remember_token
  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 100 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  validates :department, length: { in: 2..50 }, allow_blank: true
  validates :basic_time, presence: true
  validates :work_time, presence: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  self.per_page = 20

  # 既存のメソッド（digest, new_token, remember, authenticated?, forget, search）はそのまま維持

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
      user = find_by(email: row["email"]) || new
      user.attributes = row.to_hash.slice(*updatable_attributes)
      user.password ||= SecureRandom.alphanumeric(8) # ランダムな8文字のパスワードを生成
      if user.save
        Rails.logger.info "User saved: #{user.attributes}"
      else
        Rails.logger.error "Failed to save user: #{user.email}, Errors: #{user.errors.full_messages.join(', ')}"
      end
    end
  end

  # ユーザーのログイン情報を破棄します。
  def forget
    update_attribute(:remember_digest, nil)
  end

  def self.updatable_attributes
    ["name", "email", "affiliation", "employee_number", "uid", "basic_work_time", "designated_work_start_time", "designated_work_end_time", "superior", "admin"]
  end
end