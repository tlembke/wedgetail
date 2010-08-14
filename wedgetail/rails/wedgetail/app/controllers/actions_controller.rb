class ActionsController < ApplicationController
  layout "standard"
  before_filter :redirect_to_ssl, :authenticate_optional

  
  # GET /actions
  # GET /actions.xml
  def index
    @ticket=params[:ticket]
    
 
        if (@ticket)
          redirect_to :action => "show", :id => @ticket
        else

          respond_to do |format|
            format.html{}
            format.iphone {render :layout=> 'layouts/application.iphone.erb'}# index.iphone.erb 
          end
    end
  end

  # GET /actions/1
  # GET /actions/1.xml
  def show
    @ticket=params[:id]

    @result=ResultTicket.find_by_ticket(params[:id])
    
    if @result
      @actions=Action.find(:all,:conditions=>["request_set=?",@result.request_set])
    end
    @code=["No further action required for this result","Please call to discuss these results","Please make an urgent appointment to discuss results"]
    unless @result
      flash[:notice] = 'That ticket number is not known.'
 
      redirect_to actions_path
    end
    if @result
      for @action in @actions
        @action.update_attribute(:viewed, 1)
      end
      respond_to do |format|
        format.html {
          }# show.html.erb
      
        format.xml  { render :xml => @action }
        format.iphone {
            render :layout=> 'layouts/application.iphone.erb'
        }# show.iphone.erb
      end
    end
  end

  # GET /actions/new
  # GET /actions/new.xml


  # GET /actions/1/edit



  def save_or_update_action(action)

    if @user  #uploaded has logged in 
      action[:created_by] = @user.wedgetail
      if action[:localID]
        @localID=action[:localID]
        action.delete("localID")
        if @localmap=Localmap.get(@user,@localID)
          action[:wedgetail]=@localmap.wedgetail
        end
      end
      # see if user authorised to access that record
      patient = User.find_by_wedgetail(action[:wedgetail],:order=>"created_at DESC")
      if patient and patient.firewall(@user)
          @notifiees<< action[:wedgetail] if action[:wedgetail]
      else
          #user not authorised or patient doesn't exist - send anonymously only
          action[:wedgetail]=""
      end
    end
    
    @new_action = Action.new(action)
    if @new_action.identifier!=''
      @check=Action.find(:first,:conditions=>["request_set=? and identifier=?",@new_action.request_set,@new_action.identifier])
      if @check
        unless @check.update_attributes(action)
            @errors<< @check.errors
        end
      else
        unless @new_action.save
            @errors<< @new_action.errors
        end
      end
    end
  
  end


  # POST /actions
  # POST /actions.xml
  def create

      @errors=[]
      # for some reason, the @action in params[:action_list][:action] 
      # doesn't work for one action only.
      # so check first
      # there may be more than one result per patient, so record all the patients that need to be notified
      # and send them in a batch at the end => notifiees
      @notifiees=[]
      unless params[:action_list][:action][0]
        #@new_action = Action.new(params[:action_list][:action])
        save_or_update_action(params[:action_list][:action])
      else
        
        for @action in params[:action_list][:action]
            save_or_update_action(@action)
        end
      end
      # don't kow how to catch parsing exception, but this doesn;t work
      #rescue REXML::ParseException
      #    @errors<<"XML parsing error"
      #end
    @errors<<"No errors" if @errors.length==0
    if @notifiees.length>0
      for @next in @notifiees
         @recipient= User.find_by_wedgetail(@next,:order=>"created_at DESC")                
         if @recipient.email.to_s != ""
             @email=WedgeMailer.deliver_result_notify(@recipient)
         end
      end
    end
    respond_to do |format|
        format.xml { render :xml => @errors, :template => 'actions/actions.xml.builder' }
    end
 

  end
  

  # PUT /actions/1
  # PUT /actions/1.xml
  def update
    @action = Action.find(params[:id])

    respond_to do |format|
      if @action.update_attributes(params[:action])
        flash[:notice] = 'Action was successfully updated.'
        format.html { redirect_to(@action) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @action.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /actions/1
  # DELETE /actions/1.xml
  def destroy
    @action = Action.find(params[:id])
    @action.destroy

    respond_to do |format|
      format.html { redirect_to(actions_url) }
      format.xml  { head :ok }
    end
  end
  
  # POST /actions/check
  # POST /actions/check.xml
  def check
  
    action_check_list = params[:action_check_list]
    @return_list=[]
    for request_set in action_check_list[:request_set]
      unless request_set.include?("%") and request_set.length<7 # prevent fishing
        @actions=Action.find(:all,:conditions => ["request_set LIKE ?",request_set])
        if @actions.length>0
          for @action in @actions
            result={
              :request_set=>@action.request_set,
              :identifer=>@action.identifier,
              :name=>@action.name,
              :test_date=>@action.test_date,
              :viewed=>@action.viewed
            }
            @return_list<<result
          end
        end
      end
      
    end
    

  
    respond_to do |format|

        format.html 
        format.xml { render :xml => @return_list, :template => 'actions/check.xml.builder' }
      
    end
  end
end
