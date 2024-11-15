# ベースイメージを指定
FROM ruby:2.7.7

# 必要なパッケージをインストール
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

# アプリケーションのディレクトリを作成
WORKDIR /myapp

# GemfileとGemfile.lockをコピーして、依存関係をインストール
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock
RUN bundle install

# プロジェクトのすべてのファイルをコピー
COPY . /myapp

# ポート番号を指定
EXPOSE 3000

# サーバーを起動
CMD ["rails", "server", "-b", "0.0.0.0"]

