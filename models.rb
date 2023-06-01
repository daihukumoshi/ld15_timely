require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    
    has_many :statuses
    has_many :comments
    has_many :tasks, :through => :statuses
    
    has_many :friends
    has_many :needs
end

class Comment < ActiveRecord::Base
    belongs_to :users
end

class Friend < ActiveRecord::Base
    belongs_to :following, class_name: "User"
    belongs_to :followed, class_name: "User"
    
end

class Status < ActiveRecord::Base
    belongs_to :tasks
    belongs_to :users
end

class Task < ActiveRecord::Base
   has_many :statuses
   has_many :comments
   has_many :users, :through => :statuses
end

class Need < ActiveRecord::Base
    belongs_to :users
end