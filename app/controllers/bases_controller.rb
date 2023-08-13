# app/controllers/bases_controller.rb
class BasesController < ApplicationController
  def index
    @bases = Base.all
  end

  def show
  end
  
  def new
    @base = Base.new
  end
  
  def edit
    @base =Base.find(params[:id])
  end

  def create
    @base = Base.new(bases_params)
    if @base.save
      flash[:success] = '新規作成に成功しました。'
      redirect_to bases_url
    else
      render :new
    end
  end

  def update
    @base =Base.find(params[:id])
    if @base.update_attributes(bases_params) #更新と保存をいっぺんにやってくれる
      flash[:success] = "ユーザー情報を更新しました"
      redirect_to bases_url
    else
      render 'edit'
    end
  end
  
  def destroy
    @base =Base.find(params[:id])
    @base.destroy
    flash[:success] = "#{@base.base_name}のデータを削除しました。"
    redirect_to bases_url
  end
  
  private

  def bases_params
    params.require(:base).permit(:base_number, :base_name, :attendance_type)
  end
end