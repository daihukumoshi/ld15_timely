class Login < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :user_name
      t.string :password_digest
      t.string :display_name
    end
    
    create_table :tasks do |t|
      t.integer :user_id
      t.string :task_name
      t.integer :minutes
    end
    
    create_table :comments do |t|
      t.integer :user_id
      t.integer :commenter_id
      t.string :comment
      t.datetime :time
    end
    
    create_table :friends do |t|
      t.integer :following_id
      t.integer :followed_id
    end
    
    create_table :statuses do |t|
      t.integer :user_id
      t.integer :task_id
    end
    
    create_table :needs do |t|
        t.integer :user_id
        t.string :needtime
    end
  end
end
