# for management of Users
# note that patients are also users

require 'open3'
include Open3

class LoginController < ApplicationController
  before_filter :redirect_to_ssl
  before_filter :authenticate, :except =>[:login,:logout,:check]
  layout "standard"

  def add_user
    # team leaders can create new providers
    # admin can create team leaders
    # wedegtail can create admins
    
    @newuser = User.new(params[:newuser])
    authorize_only (:leader) {
      @newuser.team = @user.team # team must be leaders team
      true
    }
    authorize :admin 
    if request.post?
      # generate wedgetail number
      if @newuser.role<=@user.role
        @newuser.errors.add(:role,"Cannot create a user with more rights than yourself")
      else
        @newuser.wedgetail=WedgePassword.make("P")
        @newuser.hatched = false
        if @newuser.save 
          flash.now[:notice] = "User #{@newuser.username} created" 
          @newuser = User.new 
        end
      end
    end
  end
  
  def add_team
    authorize :admin
    @newuser = User.new(params[:newuser]) 
    if request.post? 
      @newuser.wedgetail=WedgePassword.make("T")
      @newuser.username=@newuser.wedgetail
      @newuser.role=6
      # @newuser.password=@newuser.object_id.to_s + rand.to_s+"T"
      #@newuser.password_confirmation=@newuser.password
      if @newuser.save
        flash.now[:notice] = "Team #{@newuser.family_name} created" 
        @newuser = User.new 
      end
    end 
  end
  
  def check
    respond_to do |format|
        format.any(:xml, :text){
          testuser = authenticate_with_http_basic do |login, password| 
            @username=login
            User.authenticate(login, password) 
          end 
          if testuser
            @status = "Confirmed"
          else 
            testuser=User.find_by_username(@username)
            if testuser
              @status="Incorrect password"
            else
              @status="Unknown user"
            end
          end
          render :xml => @status, :layout=>'layouts/blank.erb',:template => 'login/check.xml.erb'
        }
      end
  end

  def login 
    session[:user_id] = nil
    if request.post? 
      user = User.authenticate(params[:name], params[:password])
      if user
        flash[:notice] = false
        if user.role<7 or (user.role==7 and user.access!=1)
          session[:user_id] = user.id
          uri = session[:original_uri] 
          session[:original_uri] = nil
          session[:expires_at] = Pref.time_out.minutes.from_now
          user.update_attribute(:access, 1)
          user.wedgetail=user.wedgetail.from(6) if user.role==7
          if (user.role==5 or user.role==7)
            #redirect_to(:controller => "record", :action => "show", :wedgetail =>user.wedgetail)
            redirect_to(patient_path(user.wedgetail))
          else
              redirect_to(uri || patients_path)  
            end
        else
          user.update_attribute(:role,8)
          flash[:notice] = "Guest user expired"
        end
        
      else 
        flash[:notice] = "Invalid user/password combination" 
      end 
    else
      respond_to do |format|
        format.html {render :layout=>'layouts/standard'}
        format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
      end
    end
  end 

  def load_certificate
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail}
    authorize_only (:leader) {@useredit.wedgetail == @user.wedgetail}
    authorize :admin  # apart from admin
    content = params[:certificate_upload][:certificate]
    if content.respond_to? :original_filename
      content = content.read
    end
    if content == ""
      flash[:error] = "Please nominate a file to upload"
      redirect_to(:action => "certificate",:wedgetail=>params[:wedgetail])
      return
    end
    if content.starts_with? "\x30\x82" # WARNING KLUDGE: this seems to work for the DER files I have seen
      cmd = "openssl x509 -inform DER -outform PEM"
      logger.debug "CMD: %s" % cmd
      result = err = ""
      popen3(cmd) do |stdin, stdout, stderr|
        stdin.write(content)
        stdin.close
        result = stdout.read
        err = stderr.read
      end
      if content.length < 20
        logger.debug("Attempt to do DER->PEM conversion gave clearly invalid data, input: %p, with error stream %p" % [content,err])
        flash[:error] = "Conversion of certificate failed"
        redirect_to(:action => "edit",:wedgetail=>params[:wedgetail])
        return
      else
        content = result
      end
    end
    # at this point we should only have PEM certificate
    # use OpenSSL to extract embedded e-mail address
    cmd = "openssl x509 -inform PEM -text"
    logger.debug "CMD: %s" % cmd
    text = ""
    popen3(cmd) do |stdin, stdout, stderr|
      stdin.write(content)
      stdin.close
      text = stdout.read
      err = stderr.read
    end
    if text.length < 20
      logger.debug("Attempted to do PEM->text conversion gave, clearly invalid data, input: %p, with error stream %p" % [content,err])
    end
    # the moment of truth, look for the e-mail
    if text =~ /email:(.*)/ or text =~ /emailAddress=([a-zA-Z0-9\.]+@[a-zA-Z0-9\.]+)/
      path = RAILS_ROOT+'/certs/'+$1
      logger.info("Saving new cert to #{path}")
      f = open(path,"w")
      f.write content
      f.close
      u = User.find_by_wedgetail(params[:wedgetail])
      u.cert = $1
      u.crypto_pref = 1 if u.crypto_pref == 0 # select X.509 as crypto preference 
      u.save!
      flash[:notice] = "Certificate Uploaded"
    else
      logger.debug("Attempt to analyse certificate failed: %p" % text)
      flash[:error] = "Analysis of certificate failed"
    end
    redirect_to(:action => "edit",:wedgetail=>params[:wedgetail]) 
  end

  def logout
    session[:user_id] = nil 
    flash[:notice] = "Logged out" 
    redirect_to(:action => "login")   
  end


  def edit
    @useredit=User.find_current(params[:wedgetail])
    @themes=Theme.find(:all, :order => "name").map {|u| [u.name, u.css] }
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail} # users can edit themselves
    authorize_only (:leader) { @useredit.team == @user.team  || @useredit.wedgetail == @user.team }
    authorize :admin #apart from admin
  end
 
  def ecollab
    # @useredit is the User being edited and @user is the current user
    @useredit=User.find_current(params[:wedgetail])
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail} # users can edit themselves
    authorize_only (:leader) { @useredit.team == @user.team  || @useredit.wedgetail == @user.team }
    authorize :admin # admins can do whatever they like
    # team leaders can edit patients, themselves, users of their team and the team itself
    authorize :admin # admins can do whatever they like
    if @useredit.update_attribute(:hatched,params[:hatched])
      flash[:notice] = 'User was successfully added to eCollabs.'
    else
      flash[:notice] = 'Error when modifying user.'
    end
    redirect_to :action => 'list_users'
      
  end
  
  
  def toggle_list
    render :update do |page|
      page.visual_effect :toggle_blind, "greylist" 
    end
  end
  
  # for changing a patients/users password and access firewall
  def password
    if @useredit=User.find_by_wedgetail(params[:wedgetail],:order=>"created_at DESC")
      # @useredit is the patient, if these is one
      authorize_only (:patient) {@useredit.wedgetail == @user.wedgetail} # everyone can only edit themselves
      authorize_only (:user) {@useredit.wedgetail == @user.wedgetail}
      authorize_only (:leader) {@useredit.wedgetail == @user.wedgetail}
      authorize :admin  # apart from admin
    else
      if(@user.role==5)
        flash[:notice]="You do not have authority to access that page"
        redirect_to(patient_path(@user.wedgetail))
      else
        flash[:notice]="User not found"
        redirect_to :controller => 'patients',:action =>'index'
      end
    end
    if @useredit.role==5
      @useredit.access=1 if @useredit.access==nil or @useredit.access=="0"
      @currentlist=User.find(:all,:conditions=>["firewalls.patient_wedgetail='#{@useredit.wedgetail}'"],:joins=>"inner join firewalls on users.wedgetail=firewalls.user_wedgetail")
    else
      @currentlist=[]
    end
    @listname="Access List"
    @access_name="me"
    if (@user.role!=5)
      @access_name="patient themselves"
    end
  end 
  
  def update_password
    @useredit = User.find_by_wedgetail(params[:useredit][:wedgetail],:order=>"created_at DESC")
    authorize_only (:patient) {@useredit.wedgetail == @user.wedgetail} # everyone can only edit themselves
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail}
    authorize_only (:leader) {@useredit.wedgetail == @user.wedgetail}
    authorize :admin #apart from admin
    if @useredit.update_attributes(params[:useredit])
      flash[:notice] = 'Preferences updated.'
      if(@user.role==5 or (@user.role<3 and @useredit.wedgetail!=@user.wedgetail))
        redirect_to :controller => 'patients',:wedgetail=>@useredit.wedgetail
      else
        redirect_to :controller => 'patients'
      end
    else  
      if @useredit.role==5
        @useredit.access=1 if @useredit.access==nil or @useredit.access=="0"
        @currentlist=User.find(:all,:conditions=>["firewalls.patient_wedgetail='#{@useredit.wedgetail}'"],:joins=>"inner join firewalls on users.wedgetail=firewalls.user_wedgetail")
      else
        @currentlist=[]
      end
      @listname="Access List"
      render :action => 'password', :wedgetail=>@useredit.wedgetail
    end
  end
  
  # a guest has once-only read access to the creating patient's record
  def guest
    @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
    authorize_only (:patient) {@patient.wedgetail == @user.wedgetail}
    authorize :admin
    @newuser = User.new
     
    @newuser.username= WedgePassword.username_make("G")
    @newuser.password= WedgePassword.random_password(6)
    @newuser.family_name="Guest "+@newuser.username
    @newuser.wedgetail=@newuser.username + @patient.wedgetail
    @newuser.role=7
    if @newuser.save 
      render(:layout => "layouts/guestcard")
      flash.now[:notice] = "Guest User Created"
    else
      flash.now[:notice] = "Guest User Not Created Due to Error"
      redirect_to(patient_path(@patient.wedgetail))
    end
  end

  
  # patient controlled access to their record
  def firewall
    @useredit=User.find_by_wedgetail(params[:wedgetail])
    authorize_only (:patient) {@useredit.wedgetail == @user.wedgetail} # everyone can only edit themselves
    authorize :admin  # apart from admin
    @currentlist=User.find(:all,:conditions=>["firewalls.patient_wedgetail='#{@useredit.wedgetail}'"],:joins=>"inner join firewalls on users.wedgetail=firewalls.user_wedgetail")
    if ! params.has_key? :show   or params[:show]=="Team"
      @search_type="Team"
      @next_search="Individual"
      @allusers=User.find(:all,:conditions=>["role=6"])
    else
      @search_type="Individual"
      @next_search="Team"
      @allusers=User.find(:all,:conditions=>["role=3 or role=4"])
    end
    @listname="greylist"
    @listname="blacklist" if @useredit.access==2
    @listname="whitelist" if @useredit.access==3
  end 

  # add a user to greylist
  def select_user
    authorize_only (:patient) {params[:useredit] == @user.wedgetail} # everyone can only edit themselves
    authorize :admin  # apart from admin
    @useredit=User.find_by_wedgetail(params[:useredit])
    @listname="greylist"
    @listname="blacklist" if @useredit.access==2
    @listname="whitelist" if @useredit.access==3
    @choice=User.find_by_wedgetail(params[:wedgetail])
    @ok=Firewall.find(:all,:conditions=>["patient_wedgetail=? and user_wedgetail=?",params[:useredit],params[:wedgetail]])
    if @ok.size>0
      # remove selected
      Firewall.delete_all(["patient_wedgetail=? and user_wedgetail=?",params[:useredit],params[:wedgetail]])
      @new_term="Add"
      @choice_name=@choice.family_name_given_names
    else
      # add seleted
      @ok=Firewall.new
      @ok.user_wedgetail=params[:wedgetail]
      @ok.patient_wedgetail=params[:useredit]
      @ok.save
      @new_term="Remove"
      @choice_name="<font color='red'>"+ @choice.family_name_given_names + "</font>"
    end
      
    @currentlist=User.find(:all,:conditions=>["firewalls.patient_wedgetail='#{@useredit.wedgetail}'"],:joins=>"inner join firewalls on users.wedgetail=firewalls.user_wedgetail")
      
    render :update do |page|
      #page.replace_html "old_wedge_"+params[:wedgetail],new_wedgetail
      page.replace_html("command_"+params[:wedgetail],link_to_remote(@new_term, :url => {:action => "select_user",:wedgetail=> params[:wedgetail],:useredit=>params[:useredit]}))
      page.replace_html("name_"+params[:wedgetail],@choice_name)
      page.replace_html("greylist",render(:partial => "firewall_current"))
    end
  end
  
  def update
    # @useredit is the User being edited and @user is the current user
    @useredit = User.find_by_wedgetail(params[:useredit][:wedgetail])
    authorize_only (:patient) {@useredit.wedgetail == @user.wedgetail} # patients can edit themselves
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail} # users can edit themselves
    authorize_only (:leader) { @useredit.team == @user.team  || @useredit.wedgetail == @user.team }
    # team leaders can edit patients, themselves, users of their team and the team itself
    authorize :admin # admins can do whatever they like
    if @useredit.update_attributes(params[:useredit])
      flash[:notice] = 'User was successfully updated.'
      redirect_to(patient_path(@useredit.wedgetail))
    else
      
      @themes=Theme.find(:all, :order => "name").map {|u| [u.name, u.css] }
      render :action => 'edit', :wedgetail=>@useredit.wedgetail
    end

  end
  
  def inactivate
    # @useredit is the User being edited and @user is the current user
    @useredit=User.find_current(params[:wedgetail])
    authorize_only (:user) {@useredit.wedgetail == @user.wedgetail} # users can edit themselves
    authorize_only (:leader) { @useredit.team == @user.team  || @useredit.wedgetail == @user.team }
    authorize :admin # admins can do whatever they like
    # team leaders can edit patients, themselves, users of their team and the team itself
    authorize :admin # admins can do whatever they like
    if @useredit.update_attribute(:role,10)
      flash[:notice] = 'User was successfully inactivated.'
    else
      flash[:notice] = 'Error when inactivated user.'
    end
    redirect_to :action => 'list_users'

  end

  def list_users
    authorize :leader
    if @user.role==3
      @thisteam=@user.team
      @all_users=User.find(:all, :conditions => ["(role = 4 or role =3) and team = '#{@thisteam}'"])     
    else
      @all_users = User.find(:all,:conditions => ["role<5 or role=10"], :order => "role") 
    end
    @role = ["","big_wedgie","admin","team leader","provider","patient","team","guest","","","inactive"]
  end
 
  def list_teams
    authorize :admin
    @all_users = User.find(:all,:conditions => ["role=6"]) 
    @role = ["","big_wedgie","admin","team leader","provider","patient","team"]
  end 
end
