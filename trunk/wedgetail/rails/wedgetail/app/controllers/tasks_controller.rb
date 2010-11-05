class TasksController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout :get_layout

  
  def get_layout
    if params[:patient_id] 
      layout= "patients"
      @patient=User.find_by_wedgetail(params[:patient_id],:order =>"created_at DESC")
   else
      layout="standard"
   end
   return layout
  end
  # GET /tasks
  # GET /tasks.xml
  def index
     if params[:patient_id] 
       @conditions=Condition.find(:all)
       @patient=User.find_by_wedgetail(params[:patient_id],:order =>"created_at DESC") 
       @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 

       
       
             
       
    else
       @tasks = Task.all
    end
    
    
    
    
    

    respond_to do |format|
      format.html {
        if params[:patient_id] 
          render :template=>"tasks/goals.html.erb"
        end
        
        
      }# index.html.erb
      format.xml  { render :xml => @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    @task = Task.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    @task = Task.new
    @goals=Goal.find(:all)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/1/edit
  def edit
    @task = Task.find(params[:id])
    @goals=Goal.find(:all)
  end
  
  def edit_task
    #called from AJAX
    @task=Task.find(params[:task_id])
    render :update do |page|
      page.replace_html("task_form_"+@task.id.to_s, :partial => "tasks/edit_task",:object=>@task)
    end
    
  end
  
  def check_task
    #called from AJAX
    @task=Task.find(params[:task_id])
    if @task.active==1
      @task.active=0
    else
      @task.active=1
    end
      
    @task.update_attribute(:active,@task.active)
    render :update do |page|
      if @task.active==0
        page<<"$('tasktext_"+@task.id.to_s+"').style.textDecoration='line-through'"
      else
        page<<"$('tasktext_"+@task.id.to_s+"').style.textDecoration='none'"
      end
    end
    
  end
  
  def save_edit_task
    #called from AJAX
    @task=Task.find(params[:task_id])
    @task.update_attributes(:title=>params[:task][:title],:description=>params[:task][:description])
    render :update do |page|
      page.replace_html("task_"+@task.id.to_s,"<b><span id='tasktext_"+@task.id.to_s+"'>"+@task.title+"</span></b> "+@task.description)
    end
    
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    @task = Task.new(params[:task])
    @task.goal_id=0 unless @task.goal_id
    respond_to do |format|
      if @task.save
        flash[:notice] = 'Task was successfully created.'
        format.html { redirect_to(@task) }
        format.xml  { render :xml => @task, :status => :created, :location => @task }
      else
        format.html { render :taskion => "new" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])

    respond_to do |format|
      if @task.update_attributes(params[:task])
        flash[:notice] = 'Task was successfully updated.'
        format.html { redirect_to(@task) }
        format.xml  { head :ok }
      else
        format.html { render :taskion => "edit" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to(tasks_url) }
      format.xml  { head :ok }
    end
  end
  
  # AJAX COMMANDS

  
   def add_new_task_to_goal
    # this is only called from AJAC
 
    unless request.xhr?
      flash[:notice]="This function not available directly"
      redirect_to(:controller => 'patients')
    else
      @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @task=Task.new(params[:newtask])
      @newtask=Task.new(params[:newtask])
      @task.team=@user.team_wedgetail
      @task.parent=0
      @task.active=1
      if params[:newtask][:goal_id]!="0"
        @goal=Goal.find(params[:newtask][:goal_id])
      end
      @task.goal_id=0 if params[:newtask][:goal_id]==""
   
      if params[:newtask][:universal].to_i==0  # not only for this patient
        @newtask.team=@user.team_wedgetail
        @newtask.parent=0
        @newtask.active=1
        if params[:newtask][:goal]!=""
          @newtask.goal_id=@goal.parent
        else  
          @newtask.goal_id=0
        end
        @newtask.save
      end
      @task.patient=@patient.wedgetail
      @task.parent=@newtask.id
      @task.save # save goal for that patient

      @conditions=Condition.find(:all)
      params[:controller]='goals'
      
     render :update do |page|
       page.replace_html("patient_tasks_"+params[:newtask][:goal_id], :partial => "tasks/patient_tasks",:object=>@goal)
       page.toggle 'add_task_'+params[:newtask][:goal_id],'new_task_'+params[:newtask][:goal_id]
     end
    end
  end
  
  def add_task_to_goal
    
    # this is only called from AJAX
    unless request.xhr?
      flash[:notice]="This function not available directly"
      redirect_to(:controller => 'patients')
    else
      @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
    
      @goal=Goal.find(params[:goal_id])
      goal_id=@goal.id.to_s
      @task=Task.find(params['task_'+goal_id][:id])
      @new_task=Task.create(:title=>@task.title,:description=>@task.description,:patient=>@patient.wedgetail,:team=>@user.team_wedgetail,:goal_id=>goal_id,:active=>1,:parent=>@task.id)
      
      @conditions=Condition.find(:all)
      params[:controller]='goals'
    
      render :update do |page|
        #page['goal_goal_id'].remove(['goal_goal_id'].selectedindex)
        page.replace_html("patient_tasks_"+goal_id, :partial => "tasks/patient_tasks",:object=>@goal)
        page<<"$('task_"+goal_id+"_id').remove($('task_"+goal_id+"_id').selectedIndex)"
 
      end
    end
  end
  
end
