class GoalsController < ApplicationController
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
 
  # GET /goals
  # GET /goals.xml

  def add_measure
    # this is only called from AJAX
    unless request.xhr?
      flash[:notice]="This function not available directly"
      redirect_to(:controller => 'patients')
    end
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
 
    value_date=Date.new(params[:date][:year].to_i,params[:date][:month].to_i,params[:date][:day].to_i)
    #value_date=value_date.strftime("%Y-%m-%d")
    @goal=Goal.find(:first,:conditions => ["measure_id=?",params[:measure]])
    @new_measurevalue=Measurevalue.create(:value_date=>value_date,:measure_id=>params[:measure],:patient=>@patient.wedgetail,:value=>params[:measurevalue][:value],:created_by=>@user.wedgetail)
    
    #@measurevalues=Measurevalue.find(:all,:conditions => ["patient=? and measure_id=?",@patient.wedgetail,params[:measure]],:order =>"value_date DESC") 
    @rows=Measurevalue.build_table(@patient.wedgetail,params[:measure])
    render :update do |page|
       page['add_measure_'+params[:measure]].hide
       page.replace_html("measurevalues_"+params[:measure], :partial => "goals/measurevalues", :object => @measurevalues)
    end
 
  end

  def index
    

     if params[:patient_id] 
       @conditions=Condition.find(:all)
       @patient=User.find_by_wedgetail(params[:patient_id],:order =>"created_at DESC") 
       @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 
       @allgoals = Goal.find(:all,:conditions => ["active=1 and (patient='0' or patient='') and (team='' or team='0' or team=?)",@user.team_wedgetail],:order =>"condition_id ASC") 
       @goals=[]
       @measurevalues=[]
       @allgoals.each do |goal|
         if goal.condition_id==0
             goal.title='[General] '+goal.title
         else 
             goal.title='['+goal.condition.name+'] '+goal.title
         end
         @goals<<[goal.title,goal.id] unless Goal.find(:first,:conditions=>["patient=? and active=1 and parent=?",@patient.wedgetail,goal.id])
       end
       @goals<<["Create a new goal...",0]
             
       
    else
       @goals = Goal.find(:all,:conditions => ["parent=0"])
    end
    @condition_id=0
    respond_to do |format|
      format.html {
        if params[:patient_id] 
          render :template=>"goals/goals.html.erb"
        end
        
        
      }# index.html.erb
      format.xml  { render :xml => @goals }
    end
  end

  # GET /goals/1
  # GET /goals/1.xml
  def show
    @goal = Goal.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @goal }
    end
  end

  # GET /goals/new
  # GET /goals/new.xml
  def new
    @goal = Goal.new
    @measures=Measure.find(:all)
    @conditions=Condition.find(:all)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @goal }
    end
  end

  # GET /goals/1/edit
  def edit
    @goal = Goal.find(params[:id])
    @measures=Measure.find(:all)
    @conditions=Condition.find(:all)
  end

  # POST /goals
  # POST /goals.xml
  def create
    # generic goals have a parent of 0.
    # goals created by admin (ie role = 1 or 2)are available to all users
    # when a goal is added to a particualr patient, a new goal will be created in the database but
    # it will have an entry in the patient field and parent field.
    # users can create generic golas that are available to them and their teams.
    # these will have a value in the team field but will have no value in the patient field, (and no parent)

    @goal = Goal.new(params[:goal])
    # defaults no measure, general condition
    # currently only one measure and condition per goal
    # todo: allow multiple measures per goal
    @goal.condition_id=0 unless @goal.condition_id
    @goal.condition_id=0 if @goal.condition_id==""
    @goal.measure_id=0 unless @goal.measure_id
 
    # otherwise goals only are displayed to the user who created them.
    @goal.team=@user.team_wedgetail
    @goal.team="" if @user.role<=2      

    respond_to do |format|
      if @goal.save
        flash[:notice] = 'Goal was successfully created.'
        # if new goal and is univeral, need to recreate the goal with blank patient field
        if @goal.patient and @goal.patient !=""
          @goal=Goal.new(:title=>@goal.title,:description=>@goal.description,:measure_id=>@goal.measure_id,:condition_id=>@goal.condition_id,:parent=>0,:patient=>"")
          @goal.patient=""
          @goal.save
        end
        format.html { redirect_to(:action=>"index") }
        format.xml  { render :xml => @goal, :status => :created, :location => @goal }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @goal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /goals/1
  # PUT /goals/1.xml
  def update
    @goal = Goal.find(params[:id])
    @goal.condition_id=0 unless @goal.condition_id
    @goal.measure_id=0 unless @goal.measure_id
    respond_to do |format|
      if @goal.update_attributes(params[:goal])
        flash[:notice] = 'Goal was successfully updated.'
        format.html { redirect_to(:action=>"index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @goal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /goals/1
  # DELETE /goals/1.xml
  def destroy
    @goal = Goal.find(params[:id])
    @goal.destroy

    respond_to do |format|
      format.html { redirect_to(goals_url) }
      format.xml  { head :ok }
    end
  end
  
 
end
