require 'bundler/setup'

Bundler.require
require 'sinatra/reloader' if development?
require './models.rb'

enable :sessions
before '/' do
    if session[:user].nil?
       redirect '/signin'
    end
end

get '/' do
    erb :index
end

#サインイン
get '/signin' do
    erb :sign_in
    
end

post '/signin' do
    user = User.find_by(user_name: params[:username])
    if user && user.authenticate(params[:password])
         session[:user] = user.id
         redirect '/'
    else
    redirect '/signin'
    end
end


#サインアップ
get '/signup' do
    erb :sign_up
end

post "/signup" do
    if User.find_by(user_name: params[:username])
        redirect '/signup'
    else
        user = User.create(user_name: params[:username], password: params[:password], password_confirmation: params[:password_confirmation], display_name: params[:display_name])
    end
    
    if user.persisted?
        session[:user] = user.id
        redirect '/'
    end
end

get '/signout' do
    session[:user] = nil
    redirect '/'
end

#検索
get '/search' do
    @follows = Friend.where(following_id: session[:id])
    erb :search
end

post '/search' do
    if User.where(display_name: params[:search_name]) 
        @results = User.where(display_name: params[:search_name])
    end
    
    #likeで部分一致検索したい
    #if User.where("user_name Like ?","% params[:search_name] %")
    #    @results = User.where("user_name Like ?","% params[:search_name] %").id
    #end
    erb :search
end

get '/search/:user_id' do
    @the_user = User.find(params[:user_id])
    erb :profile
end

#タスク一覧
get '/task' do
    erb :task
end

post '/task/add' do
    Task.create(user_id: session[:user], task_name: params[:task_name], minutes: params[:minutes])
    redirect '/task'
end

post '/task/:task_id/delete' do
    Task.find(params[:task_id]).destroy
    redirect '/task'
end

get '/task/:task_id/edit' do
    @task_id = params[:task_id]
    erb:edit
end

post '/task/:task_id/edit' do
    Task.find(params[:task_id]).update(task_name: params[:task_name], minutes: params[:minutes])
    redirect '/task'
end

#出発前
get '/prep' do
    
    if Task.count == 0
        redirect '/task'
    else
        if params[:required_time]
            Need.create(user_id: session[:user], needtime: params[:required_time], pushtime: Time.now)
        end
        
        @leave = 1;
        erb :mypage
    end
end

post '/prep/:task_id/done' do
    Status.create(user_id: session[:user], task_id: params[:task_id])
    redirect '/prep'
end

post '/prep/:task_id/clear' do
    Status.find_by(user_id: session[:user], task_id: params[:task_id]).delete
    redirect '/prep'
end

#post '/:user_name/follow' do
#    User.find_by(user_name: params[:user_name]).id.active_friends.create(follower_id: session[:user_id])
#end

#post '/:user_name/unfollow' do
#    User.find_by(user_name: params[:user_name]).id.active_friends.destroy(follower_id: session[:user_id])
#end

post '/prep/fin' do
    Status.where(user_id: session[:user]).destroy_all
    #if Need.find_by(user_id: session[:user]).present?
        Need.where(user_id: session[:user]).destroy_all
        #Need.destroy(Need.find_by(user_id: session[:user]).id)
    #end
    
    if Comment.find_by(user_id: session[:user]).present?
        Comment.where(user_id: session[:user]).destroy_all
    end
    
    @leave = nil;
    
    redirect '/'
end

post '/:user_id/follow' do
    Friend.create(following_id: session[:user], followed_id: params[:user_id])
    
    @the_user = User.find(params[:user_id])
    erb :profile
end

post '/:user_id/unfollow' do
    Friend.find_by(following_id: session[:user], followed_id: params[:user_id]).id
    Friend.destroy(Friend.find_by(following_id: session[:user], followed_id: params[:user_id]).id)
    
    @the_user = User.find(params[:user_id])
    erb :profile
end

post '/:user_id/comment' do
    Comment.create(user_id: params[:user_id], commenter_id: session[:user], comment: params[:comment], time: Time.now)
    @the_user = User.find(params[:user_id])
    erb :profile
end


#アカウント登録重複ないように
