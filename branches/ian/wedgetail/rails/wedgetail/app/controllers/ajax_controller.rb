class AjaxController < ApplicationController

  
  def activities
    @consultation = Consultation.find(params[:id])
    @user=@consultation
    @all=Activity.find(:all)
    @pending_todos=[]
    @completed_todos=@consultation.activities
    for each_act in @all
      if not @completed_todos.include? each_act
        @pending_todos << each_act
      end
    end
  end
  
  def todo_completed
    @consultation = Consultation.find(params[:id])
    @consultation.activities << Activity.find(params[:todo])
    @user=@consultation
    @all=Activity.find(:all)
    @pending_todos=[]
    @completed_todos=@consultation.activities
    for each_act in @all
      if not @completed_todos.include? each_act
        @pending_todos << each_act
      end
    end
    render :update do |page|
      page.replace_html 'pending_todos', :partial => 'pending_todos'
      page.replace_html 'completed_todos', :partial => 'completed_todos'
      #page.sortable "pending_todo_list", 
      #   :url=>{:action=>:sort_pending_todos, :id=>@user}
    end
  end
  
  def todo_pending
    @consultation = Consultation.find(params[:id])
    @consultation.activities.delete(Activity.find(params[:todo]))
    @user=@consultation
    @all=Activity.find(:all)
    @pending_todos=[]
    @completed_todos=@consultation.activities
    for each_act in @all
      if not @completed_todos.include? each_act
        @pending_todos << each_act
      end
    end
    render :update do |page|
      page.replace_html 'pending_todos', :partial => 'pending_todos'
      page.replace_html 'completed_todos', :partial => 'completed_todos'
      #page.sortable "pending_todo_list", 
      #   :url=>{:action=>:sort_pending_todos, :id=>@user}
    end
  end
  
  private

  def update_todo_completed_date(newval)
    @user = User.find(params[:id])
    #@todo = @user.todos.find(params[:todo])
    #@todo.completed = newval
    #@todo.save!
    @completed_todos = @user.completed_todos
    @pending_todos = @user.pending_todos
    render :update do |page|
      page.replace_html 'pending_todos', :partial => 'pending_todos'
      page.replace_html 'completed_todos', :partial => 'completed_todos'
      #page.sortable "pending_todo_list", 
      #   :url=>{:action=>:sort_pending_todos, :id=>@user}
    end
  end
  
 



end