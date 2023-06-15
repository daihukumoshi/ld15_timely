require 'bundler/setup'

Bundler.require
require 'sinatra/reloader' if development?
require 'open-uri'
require 'sinatra/json'
require './models.rb'

enable :sessions

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
end

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
    img_url=''
    if params[:file]
        img = params[:file]
        tempfile = img[:tempfile]
        upload = Cloudinary::Uploader.upload(tempfile.path)
        img_url = upload['url']
    end
    
    if params[:comment].nil? && img_url==''
        erb :profile
    else
        Comment.create(user_id: params[:user_id], commenter_id: session[:user], comment: params[:comment], time: Time.now, img: img_url, reaction: false)
        @the_user = User.find(params[:user_id])
        erb :profile
    end
end

post '/:comment_id/permit' do
    Comment.find(params[:comment_id]).update(reaction: true);
    erb :mypage
end



helpers do
    def time_arrivehour current_id
        sum = 0
        tasks = Task.where(user_id: current_id)
        for task in tasks do
            sum = sum + task.minutes
        end
        tasks_done = Status.where(user_id: current_id) 
        for task_done in tasks_done
            tasks_done_minutes = Task.where(id: task_done.task_id)
            for task_done_minutes in tasks_done_minutes
                sum = sum - task_done_minutes.minutes
            end
        end
        need_hour = sum / 60
        need_minutes = sum % 60
        
        
            
        time = Time.now
        @leave_hour = time.hour.to_i + 9 + need_hour.to_i
        @leave_min = time.min.to_i + need_minutes.to_i
        if @leave_min > 60
            over = @leave_min / 60
            @leave_min = @leave_min % 60
            @leave_hour = @leave_hour + over
        end
        
        if @leave_hour > 24
            @leave_hour = @leave_hour % 24
        end
        
        disp_min = @leave_min.to_s
        if @leave_min < 10
            disp_min = "0" + disp_min
        end
        
        return "#{@leave_hour.to_i}:#{disp_min}"
    end
    
    
    def time_depart current_id
        if Need.find_by(user_id: current_id).present?
            required_array = Need.where(user_id: current_id).last.needtime.split(":") 
            required_hour = required_array[0]
            required_minute = required_array[1]
        
            arrive_hour = @leave_hour.to_i + required_hour.to_i
            arrive_min = @leave_min.to_i + required_minute.to_i
        
            if arrive_min > 60
                over = arrive_min / 60 
                arrive_min = arrive_min % 60 
                arrive_hour = arrive_hour + over 
            end 
        
            if arrive_hour > 24
                arrive_hour = arrive_hour % 24 
            end
    
            disp_min_arrive = arrive_min.to_s 
            if arrive_min < 10
                disp_min_arrive = "0" + disp_min_arrive 
            end 
            
            return "#{arrive_hour.to_i}:#{disp_min_arrive}"
        end
    end
end


#アカウント登録重複ないように
