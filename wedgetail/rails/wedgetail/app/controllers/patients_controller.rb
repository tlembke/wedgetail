class PatientsController < ApplicationController
  before_filter :redirect_to_ssl,:authenticate
  layout "patients"
  auto_complete_for :condition, :name
  
  # GET /patients
  # GET /patients.xml
  def index
    authorize :user
    if params[:wedgetail] and params[:wedgetail]!=""
      @patients = User.find(:all,:order => "created_at DESC",:conditions => ["role=5 and wedgetail=?",params[:wedgetail]])
    else
      @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])
    end
    if @patients.length==0 and (params[:family_name] or params[:given_names])
      flash[:notice]='Patient not found'
    else
      if flash[:notice]=='Patient not found'
        flash.delete(:notice)
      end
    end
    respond_to do |format|
      format.html {render :layout=>'layouts/standard'}
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
      format.text { render_text_data(@patients,[:wedgetail,:family_name,:given_names,:known_as,:dob,:sex,:address_line,:town,:postcode,:medicare]) }
    end
  end

  # GET /patients/1
  # GET /patients/1.xml

  
  def show
    # no way for map.resources to use other than :id, which we don't want
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    
      
      if !@patient or @patient.role!=5
        flash[:notice]='Patient not found'
      elsif !@patient.hatched and Pref.unhatched_access==1
        flash[:notice]='Patient not yet registered'
      else
        authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
        authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
        authorize_only(:leader){@patient.firewall(@user)}
        authorize_only(:user){@patient.firewall(@user)}
        authorize :admin
        @narratives=Narrative.find(:all, :conditions=>["narrative_type_id IS NOT NULL and wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
        @audit=Audit.create(:patient=>params[:wedgetail],:user_wedgetail=>@user.wedgetail)
        @special=Array.new
        @count=Array.new
        @displayOrder=[1,5,12,3,8,9,6]
        j=1
        for i in @displayOrder
          @special[j]=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=?",params[:wedgetail],i], :order=>"narrative_date DESC,created_at DESC") 
          @count[i]= Narrative.count(:all,:conditions=>["wedgetail='#{params[:wedgetail]}' and narrative_type_id='#{i}'"])
          j=j+1
        end
        @wall_info=get_wall(@patient.wedgetail)
        @medication=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=2",params[:wedgetail]], :order=>"created_at DESC")
        unless @medication
          @medication=Narrative.create(:wedgetail=>@patient.wedgetail,:content=>"",:narrative_type_id=>2,:created_by=>@user.wedgetail,:content_type=>"text/plain")
          
        end
        
        @allergy=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=5",params[:wedgetail]], :order=>"created_at DESC")
        unless @allergy
          @allergy=Narrative.create(:wedgetail=>@patient.wedgetail,:content=>"",:narrative_type_id=>5,:created_by=>@user.wedgetail,:content_type=>"text/plain")
        end
        # get patients conditions
        @conditions=@patient.conditions
      end
     
   
    respond_to do |format|
      format.html{
        if !@patient or @patient.role!=5
          redirect_to :action=>:index
        elsif ! @patient.hatched and Pref.unhatched_access==1
          render :action=>:unconfirmed
        end
      }
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml  { render :xml => @patient }
    end
  end
  
  def redraw_wall

     @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
     authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
     authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
     authorize_only(:leader){@patient.firewall(@user)}
     authorize_only(:user){@patient.firewall(@user)}
     authorize :admin
     start=params[:start].to_i+params[:limit].to_i if params[:command]=="more"
     start=params[:start].to_i- params[:limit].to_i if params[:command]=="less"
     start=0 if start<0
     @wall_info=get_wall(@patient.wedgetail,params[:condition_id],start,params[:limit])
     render :update do |page|
        page.replace_html("built_wall", :partial => "wall", :object => @wall)
     end
  end
  

  
  def add_post
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    authorize_only (:patient) {params[:wedgetail] == @user.wedgetail}
    authorize_only (:temp) {params[:wedgetail] == @user.wedgetail.from(6)}
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    @narrative = Narrative.new(:wedgetail=>params[:wedgetail],:content=>params[:post],:narrative_type_id=>17,:condition_id=>params[:condition_id])
    @narrative.created_by=@user.wedgetail
    if ! @narrative.narrative_date or @narrative.narrative_date ==""
      @narrative.narrative_date=Date.today.to_s
    end
    @narrative.save
    @wall_info=get_wall(params[:wedgetail],params[:condition_id])
    
    render :update do |page|
       page.replace_html("built_wall", :partial => "wall", :object => @wall)
    end
  end
  
  def add_condition

      @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @new_condition=params[:condition]
      unless @condition=Condition.find(:first, :conditions=>["name=?",@new_condition[:name]]) # already exists
        @condition = Condition.create(:name=>@new_condition[:name])
      end
      # see if patient already linked to that condition (can't have it twice)
      unless PatientsCondition.find(:first, :conditions=>["wedgetail=? and condition_id=?",@patient.wedgetail,@condition.id])
          PatientsCondition.create(:wedgetail=>@patient.wedgetail,:condition_id=>@condition.id)
      end
      @conditions=@patient.conditions
      render :update do |page|
         page.replace_html("conditions_list", :partial => "conditions", :object => @conditions)
         page[:condition_name].clear
         page[:condition_name].focus
      end
  end
  
  def team
    @patient=User.find_by_wedgetail(params[:id],:order =>"created_at DESC")
    @members=get_team()
    @crafts=Craft.get_crafts
    @craftgroups=Craft.get_craftgroups
    @allusers = User.find(:all, :order => "family_name,given_names",:conditions=>"role<5")
    render :template=>"teams/team.html.erb"
    
  end
  
  def add_team_member_wedge
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    @member=User.find_current(params[:member][:member])
    @new_team_entry=Team.create(:member=>@member.wedgetail,:patient=>@patient.wedgetail,:confirmed=>0,:craft_id=>@member.craft_id,:name=>@member.full_name)
    @members=get_team(@patient.wedgetail)
    render :update do |page|
       page.replace_html("careteam", :partial => "teams/careteam", :object => @members)
    end
 
  end
  
  def add_goal_to_patient
    # this is only called from AJAC
    unless request.xhr?
      flash[:notice]="This function not available directly"
      redirect_to(:controller => 'patients')
    else
      @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
    
      @goal=Goal.find(params[:goal][:goal_id])

      @new_goal=Goal.create(:title=>@goal.title,:description=>@goal.description,:patient=>@patient.wedgetail,:condition_id=>@goal.condition_id,:measure_id=>@goal.measure_id,:active=>1,:parent=>@goal.id)
      if params[:condition_id] and params[:condition_id]!="0"
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1 and condition_id=?",@patient.wedgetail,params[:condition_id]]) 
      else
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 
      end
      @allgoals = Goal.find(:all,:conditions => ["active=1 and (patient='0' or patient='') and condition_id=?",params[:id]],:order =>"condition_id ASC") 
      @goals=[]
      @measurevalues=[]
      @allgoals.each do |goal|
        goal.title='['+goal.condition.name+'] '+goal.title
      
        @goals<<goal unless Goal.find(:first,:conditions=>["patient=? and active=1 and parent=?",@patient.wedgetail,goal.id])
      
      end
 
      if params[:condition_id]=="0"
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 
      else
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1 and condition_id=?",@patient.wedgetail,params[:condition_id]]) 
      end
    
    
      render :update do |page|
        #page['goal_goal_id'].remove(['goal_goal_id'].selectedindex)
        page<<"$('goal_goal_id').remove($('goal_goal_id').selectedIndex)"
        page.replace_html("patient_goals", :partial => "goals/patient_goals", :object => @patient_goals)
      end
    end
  end
  
  def add_new_goal_to_patient
    # this is only called from AJAC
    unless request.xhr?
      flash[:notice]="This function not available directly"
      redirect_to(:controller => 'patients')
    else
      @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @goal=Goal.new(params[:newgoal])
      @newgoal=Goal.new(params[:newgoal])
      @goal.team=@user.team_wedgetail
      @goal.parent=0
      @goal.active=1
      @goal.condition_id=0 if params[:newgoal][:condition_id]==""
   
      if params[:newgoal][:universal].to_i==0  # not only for this patient
        @newgoal.team=@user.team_wedgetail
        @newgoal.parent=0
        @newgoal.active=1
        @newgoal.condition_id=0 if params[:newgoal][:condition_id]==""
        @newgoal.save
      end
      @goal.patient=@patient.wedgetail
      @goal.parent=@newgoal.id
      @goal.save # save goal for that patient
      if params[:condition_id]=="0"
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 
      else
        @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1 and condition_id=?",@patient.wedgetail,params[:condition_id]]) 
      end
      render :update do |page|
       page.replace_html("patient_goals", :partial => "goals/patient_goals", :object => @patient_goals)
       page.toggle 'add_goal','new_goal'
       
      end
    end
  end
  
  def add_team_member_plain
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    error=0
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    if params[:member_plain][:craft_id]==""
      # new role should be specified
      if params[:member_plain][:new_role]==""
        error=1
      else
        @role=Craft.create(:name=>params[:member_plain][:new_role].titleize,:craftgroup_id=>params[:member_plain][:craftgroup_id])
        params[:member_plain][:craft_id]=@role.id
      end
    end
    @new_team_entry=Team.create(:name=>params[:member_plain][:name],:patient=>@patient.wedgetail,:confirmed=>0,:craft_id=>params[:member_plain][:craft_id])
    @members=get_team(@patient.wedgetail)
    render :update do |page|
       page.replace_html("careteam", :partial => "teams/careteam", :object => @members)
    end
 
  end
  
  def set_summary_content

      # this is to overide the usual in_place_edit so as to create a new narrative rather than update the old one
     # unless [:post, :put].include?(request.method) then
     #   return render(:text => 'Method not allowed', :status => 405)
     # end
      # the narrative id is in the field editorId=>"summary_content_xx_in_place_editor"
      # needs narrative to find patient
      narrative_id=params[:editorId].delete("summary_content_")
      narrative_id=narrative_id.delete("_in_place_editor")
      @narrative=Narrative.find(narrative_id)
      @patient=User.find_by_wedgetail(@narrative.wedgetail,:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @item=Narrative.create(:wedgetail=>@patient.wedgetail,:narrative_date=>Date.today,:narrative_type_id=>@narrative.narrative_type_id,:content=>params[:value],:created_by=>@user.wedgetail,:content_type=>"text/plain",:condition_id=>@narrative.condition_id)
      @text=@item.content.to_s
      @text=simple_format(@text)
      @text="-----------" if @text.blank?
      if @item.narrative_type_id!=2 and @item.narrative_type_id!=5 
        render :text=>@text
      else
        render :update do |page|
          @summary=@item
          page.replace_html(params[:editorId],@text)
          #page.alert("return false;")
          page.replace_html("author",:partial=>"patients/author")
        end
      end
      
      # this is the updated bit if you need to change more than one element
      # left here for reference only
      #render :update do |page|
      #    page.replace_html(params[:editorId],@text)
      #    if @item.content.blank?
      #      # can't use item.id as item.id as changed! Use narrative_id, which is constant
      #      page.show("edit_button_"+narrative_id)
      #    else
      #      page["edit_button_"+narrative_id].hide
      #      page.alert("edit_button_"+narrative_id)
      #    end
      #end

      
 
  end
  
  def rsvp
    if @team=Team.find(:first,:conditions=>["patient=? and member=? and confirmed=1",params[:wedgetail],@user.wedgetail])
      @team.update_attributes(:confirmed => 2)
      wall=@user.full_name+" has agreed to collaborate in care plan"
      Narrative.add_post_to_wall(params[:wedgetail],@user.wedgetail,wall)
      render :update do |page|
        page.replace_html("rsvp", "Thanks")

      end
    end
  end
  
  def get_confirmed_options
    @confirmed = %w{ Unconfirmed Pending Wedgetail Person Fax Letter Email}
    @option_string=""
    count=0
    @confirmed.each do |option|
      @option_string=@option_string+"<option value='" + count.to_s
      @option_string=@option_string +"'>"+ option +"</option>"
      count=count+1
    end  
    
  end
  def get_team(patient=params[:id])
      @confirmed=get_confirmed_options()
      @members=Team.find(:all,:conditions=>["patient=?",patient])
      
  end
  
  def confirm_team_member
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    @team=Team.find(params[:team])
    @team.update_attribute(:confirmed, params[:confirm])
    @confirmed=get_confirmed_options()
    status=""
    status="Pending" if params[:confirm]=="1"
    render :update do |page|
      page['confirm_'+@team.id.to_s].hide
      page.replace_html('status_'+@team.id.to_s,status)
      #page.replace_html("confirm_string_"+@team.id.to_s, @confirmed[@team.confirmed])
    end
  end
  
  #display narrative


  # GET /patients/new
  # GET /patients/new.xml
  def new

    authorize :user
    @patient = User.new
    respond_to do |format|
      format.html {render :layout=>'layouts/standard'} # new.html.erb
      format.xml  { render :xml => @patient }
    end
  end

  # GET /patients/1/edit
  def edit
    w = params[:wedgetail]
    authorize_only (:patient) {w == @user.wedgetail}
    authorize_only (:temp) {w == @user.wedgetail.from(6)}
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC") 
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    render :layout=>'layouts/standard'
  end
  


  # POST /patients
  # POST /patients.xml
  def create
      authorize :user
      # have to delete localID attribute as it is not in Users model
      # and will generate an unknow attribute error
      failflag=""
      force=""
      
      # first check to see if 'force' in place
      if params[:patient][:force] and params[:patient][:force]=="true"
        force="true"
        params[:patient].delete("force")
      end
        
      # see if patient with that localID has already been created by this user
      if params[:patient][:localID]
        @localID=params[:patient][:localID]
        params[:patient].delete("localID")
        if @localmap=Localmap.get(@user,@localID)
          #patient with that localID already exists - don't create
          failflag="Error 01: Patient with that localID already created"
          @patient=User.find_by_wedgetail(@localmap.wedgetail)
          @patients=[@patient]
        end
      end
          # see if that patient already has a wedgetail record, unless force is true
      unless force=="true"
          if failflag==""
            conditions="family_name=? and dob=?",params[:patient][:family_name],params[:patient][:dob]
            @patients=User.find(:all,:conditions=>conditions,:order=>'created_at DESC')
            if @patients.length>0
                failflag="Error 02: Patient possibly already created"
            end
          end
      end
      
      if failflag==""
        @patient = User.new(params[:patient])
        if params[:ihi] and params[:ihi]!=""
          @patient.wedgetail=params[:ihi]
        else
          # generate temporary wedgetail number
          wedgetail_number=WedgePassword.make("H")
          @patient.wedgetail=wedgetail_number
        end
        @patient.username = @patient.wedgetail
        @patient.role=5
        @patient.hatched=false
        @patient.hatched=true if request.host.starts_with?("de")
        @patient.created_by=@user.wedgetail
        @patient.access=1
        if Pref.unhatched_access ==2
          @patient.access=3
          @patient.addToWhiteList(@user.wedgetail)
        end
        if Pref.unhatched_access == 3
          @patient.access=3
          if @user.team
            @patient.addToWhiteList(@user.team)
          else
            @patient.addToWhiteList(@user.wedgetail)
          end
        end
        if Pref.unhatched_access ==4
          @patient.access=4
        end      
        
      end

      respond_to do |format|
        if failflag=="" and @patient.save
          
          if @localID
            @team=@user.wedgetail
            @team=@user.team if @user.team and @user.team !="" and @user.team !='0'
            Localmap.create(:team=>@team,:localID=>@localID,:wedgetail=>@patient.wedgetail)
          end
          
          format.html { 
            flash[:notice] = 'Patient was successfully created.'
            redirect_to patient_url(@patient.wedgetail)
          }
          format.xml  { 
            @message="Patient Created"
            @patients=[@patient]
            render :xml => @patients, :template => 'patients/patients.xml.builder', :status => :created 
          }
          format.text { render_text_ok } 
        else
          if failflag==""
            failflag=@patient.errors.each_full {|msg| p msg}
          end
          format.html { render :action => :new,:layout=>'layouts/standard'}
          format.xml {
            @message=failflag
            logger.error failflag
            # used to send :status => :unprocessable_entity but this returns a 422 error 
            # which causes .NET to throw an exception
            render :xml => @patients, :template => 'patients/patients.xml.builder' #,:status => :unprocessable_entity 
          }
          format.text { render_text_error(failflag) }
        end # if
      end # respond_to
  end # def

  
  # PUT /patients/1
  # PUT /patients/1.xml
  
  def update
    w = params[:patient][:wedgetail]
    authorize_only (:patient) {w == @user.wedgetail}
    authorize_only (:temp) {w == @user.wedgetail.from(6)}
    @patient=User.find_by_wedgetail(w,:order =>"created_at DESC") 
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
 
    @patient.update_attributes(params[:patient])
    if @patient.save
      flash[:notice] = 'Patient was successfully updated.'
      redirect_to :action => 'show', :id => @patient.wedgetail
    else
      if @patient.dob.blank?
        @patient.dob = @patient.dob_was 
      end
      render :action => 'edit'
    end
  end



#  GET patients/1/results
def results
  # no way for map.resources to use other than :id, which we don't want
  params[:wedgetail]=params[:id]
  @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
  
    
    if !@patient or @patient.role!=5
      flash[:notice]='Patient not found'
    elsif !@patient.hatched 
      flash[:notice]='Patient not yet registered'
    else
      authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
      authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      @actions=Action.find(:all, :conditions=>["wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
    end
   
  respond_to do |format|
    format.html{
      if !@patient or @patient.role!=5
        redirect_to :action=>:index
      elsif ! @patient.hatched
        render :action=>:unconfirmed
      else
        render :action=>:results
      end
    }
    format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
    format.xml  { render :xml => @patient }
  end
end

  
  def search 
    @patients = @user.find_authorised_patients(params[:family_name],params[:given_names],params[:dob])  
    respond_to do |format|
      format.html # search.html.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
      format.text { render_text_data(@patients,[:wedgetail,:family_name,:given_names,:known_as,:dob,:sex,:address_line,:town,:postcode,:medicare]) }
    end 
  end

  # show all users who access a patient's information
  def audit
     @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
     authorize_only (:patient) {@patient.wedgetail == @user.wedgetail}
     authorize :user
     @audits = Audit.paginate(:page => params[:page],:per_page => 60, :order => 'created_at DESC', :conditions => ["patient=?", params[:wedgetail]])
  end

        # if a user has registered an interest in a patient, they will receive a copy of all new narratives
   def register
       wedgetail = params[:wedgetail]
       @interest=Interest.create(:patient => wedgetail, :user =>@user.wedgetail)
       text=<<EOF
<a href="#" onclick="new Ajax.Request('/patients/unregister/#{wedgetail}', 
{asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader" border="0" id="internet-news-reader" src="/images/icons/tango/large/internet-news-reader.png" valign="middle" />
<script>new Tip("internet-news-reader",
"You have been registered to receive HL7 updates on this patient. Click to unregister",{title:'Thanks for registering'});
</script></a>
EOF
            render :update do |page|
                page.replace_html "register",text
            end
     end
     
def unregister
     wedgetail = params[:wedgetail]
     Interest.delete_all(["patient = '#{wedgetail}' and user='#{@user.wedgetail}'"])
     text=<<EOF
<a href="#" 
onclick="new Ajax.Request('/patients/register/#{wedgetail}', {asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader-x" border="0" id="internet-news-reader-x" src="/images/icons/tango/large/internet-news-reader-x.png" valign="middle" />
<script>new Tip("internet-news-reader-x",
"You have been unregistered from receiving updates about this patient. Click to re-register.",{title:'Thanks for unregistering'});
</script></a>
EOF
     render :update do |page|
     page.replace_html "register", text
      end
end 

  # guests have one time read only access to a particular patient
  def guests
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    if params[:commit]=="Save changes"
      @thisguest=User.find_by_username(params[:user][:username])
      @thisguest.update_attributes(:family_name=>params[:user][:family_name],:given_names=>params[:user][:given_names])
    end 
    @guests=User.find(:all,:conditions=>["wedgetail LIKE ? and wedgetail !=?","%"+ params[:wedgetail],params[:wedgetail]])
  end

  # generates the consent for new patients, text found in /public/consent.txt
  def consent
    send_data(gen_pdf(params[:wedgetail]), :filename => "consent.pdf", :type => "application/pdf")
  end
  
  def careplan
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    @conditions=@patient.conditions
    @medication=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=2",params[:wedgetail]], :order=>"created_at DESC")
    @summary=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=1",params[:wedgetail]], :order=>"created_at DESC")
    @patient_goals = Goal.find(:all,:conditions => ["patient=? and active=1",@patient.wedgetail],:order =>"condition_id ASC") 
    @members=get_team(@patient.wedgetail)
    @crafts=Craft.get_crafts
    @craftgroups=Craft.get_craftgroups
    respond_to do |format|
      format.html {render :layout=>'layouts/patients'}
      format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      format.xml { render :xml => @patients, :template => 'patients/patients.xml.builder' }
      format.text { render_text_data(@patients,[:wedgetail,:family_name,:given_names,:known_as,:dob,:sex,:address_line,:town,:postcode,:medicare]) }
      format.pdf  {render :pdf => "careplan",
                   :template => 'patients/careplan.pdf.erb',
                   :layout => 'pdf.html',
                   :outline => false,
                   :show_as_html => !params[:debug].blank?,
                   :footer => {
                                      :left => "Care Plan for "+@patient.full_name,
                                      :right => Date.today.strftime("%d/%m/%y"),
                                      :center=> "http://wedgetail.org.au",
                                      :font_size=>8
                   }
      }
    end
  end
  
  def wall
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    @wall_info=get_wall(@patient.wedgetail)
  end
  
  def unconfirmed
    params[:wedgetail]=params[:id]
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
  end

  def gen_pdf(wedgetail)
    patient=User.find_by_wedgetail(wedgetail,:order =>"created_at DESC")
    patient_name=patient.full_name
    patient_text="DOB - "+patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s + "\n"
    patient_text+= patient.address_line + "\n" + patient.town+"\n"
    patient_text+= "Wedgetail: "+wedgetail
    patient_address=patient.address_line + ", " + patient.town
    patient_dob=patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s
    consent_text= IO.read(RAILS_ROOT + "/public/consent.txt") 
    consent_text=consent_text.sub("<patient_full_name>",patient_name)
    consent_text=consent_text.sub("<patient_address>",patient_address)
    consent_text=consent_text.sub("<patient_dob>",patient_dob)
    consent_text=consent_text.sub("<wedgetail_number>",wedgetail)

    pdf=FPDF.new
    pdf.AddPage
    pdf.SetFont('Arial','B',16)
    #a0aeb9
    pdf.SetFillColor(160,174,185)
    pdf.Image(RAILS_ROOT + '/public/images/wedgetail_vert_250.jpg', 10, 8, 50)

    pdf.SetX(55)
    pdf.Cell(100,10,'Patient Consent Form',0 ,1,'C');

    pdf.SetY(20)


    pdf.SetFont('Arial','B',16)
    pdf.SetX(75)
    pdf.MultiCell(100,7,patient_name,0,'R');
    pdf.SetX(75)
    pdf.SetFont('Arial','',10)
    pdf.MultiCell(100,5,patient_text,0,'R');
    pdf.Write(5,consent_text)
    pdf.SetX(25)
    pdf.SetY(-60)        
    pdf.MultiCell(100,7,"Sign...................................................\nName: "+patient_name+"\n\nDate.............",0,"L")
    pdf.SetLeftMargin(100)
    pdf.SetY(-60)
    pdf.MultiCell(200,7,"Witness...............................................\nName:..................................................\nPosition................................................\nDate........................................",0,"L")


    pdf.Output 
  end
  
  def toggle
    render :update do |page|
      page.visual_effect :toggle_blind, params[:div]
      page.toggle params[:div]+'_show',params[:div]+'_hide'
    end
  end
end
