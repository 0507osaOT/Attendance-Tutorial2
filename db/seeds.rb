# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)

# 上長A
User.create(name: "上長A",
            email: "super-1@email.com",
            password: "password",
            password_confirmation: "password",
            superior: true)

# 上長B            
User.create(name: "上長B",
            email: "super-2@email.com",
            password: "password",
            password_confirmation: "password",
            superior: true)

# 部長            
User.create(name: "部長",
            email: "super-3@email.com",
            password: "password",
            password_confirmation: "password",
            superior: true)
end
