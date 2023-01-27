class Users::SearchesController < ApplicationController
  def index
    @users = user.search(params[:keyword])
    @search_word = params[:keyword]
  end
end
