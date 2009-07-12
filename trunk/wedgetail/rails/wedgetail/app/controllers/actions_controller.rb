class ActionsController < ApplicationController
  layout "standard"
  
  # GET /actions
  # GET /actions.xml
  def index
    @ticket=params[:ticket]
    respond_to do |format|
      format.html{
        if (@ticket)
          redirect_to :action => "show", :id => @ticket

          
        end
      }
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
    
    respond_to do |format|
      format.html {
        unless @result
          flash[:notice] = 'That ticket number is not known.'
          redirect_to actions_path
        end
        
      }# show.html.erb
      format.xml  { render :xml => @action }
    end
  end

  # GET /actions/new
  # GET /actions/new.xml
  def new
    @action = Action.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @action }
    end
  end

  # GET /actions/1/edit
  def edit
    @action = Action.find(params[:id])
  end


  def save_or_update_action(action)
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
end
