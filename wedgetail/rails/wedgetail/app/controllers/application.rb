# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_wedgetail_session_id'

  private 
  
  def redirect_to_ssl

      @redirect_flag=0
      unless (request.ssl? or local_request? or not Pref.use_ssl) 
        @redirect_flag=1
        redirect_to :protocol => "https://"  
      end
       
  end
  
  
  # Check to see if logged in.
  # If not, allow log in
  def authenticate
    unless @redirect_flag==1
      unless @user=User.find_by_id(session[:user_id]) 
        # Not currently logged in
        # Save original destination so can return when logged in
        session[:original_uri] = request.request_uri 
        # Check to see if there are any users. If not, create Admin
        if User.count==0
          User.create(:username => 'admin', :family_name=>"Admin", :given_names=> "", :password => 'admin',:password_confirmation => 'admin',:role=>2,:wedgetail=>1)
          @user=User.find_by_wedgetail(1)
          session[:user_id] = @user.id 
          session[:expires_at] = Pref.time_out.minutes.from_now
          flash[:notice] = "Server ID required"
          redirect_to(:controller => "prefs", :action => "edit", :id =>1)
        else
          flash[:notice] = "Please log in" 
          redirect_to(:controller => "login", :action => "login") 
        end
      else
        # alredy logged in
        unless session[:expires_at]
          session[:expires_at] = Pref.time_out.minutes.from_now
        end
        @time_left = (session[:expires_at] - Time.now).to_i 
        unless @time_left > 0
          if @user.role==7
            # once only guest user
            @user.update_attribute(:role,8)
          end
          session[:user_id] = nil  
          flash[:notice] = "Session Timed Out" 
          session[:original_uri] = request.request_uri 
          erase_render_results
          redirect_to(:controller => "login", :action => "login") 
        end 
        #session[:expires_at] = Pref.time_out.minutes.from_now
        session[:expires_at] = Pref.time_out.minutes.from_now
      end
      @authorized = false
      true
    end
  end
  

  
  
  # Check to see if access allowed to requested page
  # if not, redirect
  def authorize_only(role,&block)
    role = {:big_wedgie=>1,:admin=>2,:leader=>3,:user=>4,:patient=>5,:temp=>7}[role]
    if (@user.role==role)
      if (block)
        if (! block.call)
          flash[:notice] = "You do not have authority to access that page!"
          @redirect =true
          if(@user.role==5)
            redirect_to :controller => 'record',:action=>'show',:wedgetail=>@user.wedgetail
          elsif(@user.role==7)
            redirect_to :controller => 'record',:action=>'show',:wedgetail=>@user.wedgetail.from(6)
          else
            redirect_to :controller => 'record'
          end
        else
          @authorized = true
        end
      else
        @authorized = true
      end
    end
  end
  
  def authorize (role)
    role = {:big_wedgie=>1,:admin=>2,:leader=>3,:user=>4,:patient=>5,:temp=>7}[role]
    if (@user.role>role && ! @authorized && ! @redirect)
       flash[:notice] = "You do not have authority to access that page!"
       if(@user.role==5)
         redirect_to :controller => 'record',:action=>'show',:wedgetail=>@user.wedgetail
       elsif (@user.role==7)
         redirect_to :controller => 'record',:action=>'show',:wedgetail=>@user.wedgetail.from(6)
      else
         redirect_to :controller => 'record'
       end
    end
  end

  def render_list (fields,list)
  # render a list of objects, fields is a list of symbols on the objects in list
    render :content_type=>'text/plain',:status=>200,:text=>proc do |response,output|
      list.each do |line|
        output.write(line.send(fields[0]))
        fields[1..-1].each do |x| 
          output.write("\t")
          output.write(line.send(x))
        end
        output.write("\r\n")
      end
    end
  end
  

end
