class ConditionsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate, :getPatient
  layout "patients"
  #in_place_edit_for :condition, :name
  #in_place_edit_for :narrative, :content
  
  def set_summary_content
      # this is to overide the usual in_place_edit so as to create a new narrative rather than update the old one
      unless [:post, :put].include?(request.method) then
        return render(:text => 'Method not allowed', :status => 405)
      end
      # the narrative id is in the field editorId=>"summary_content_xx_in_place_editor"
      narrative_id=params[:editorId].delete("summary_content_")
      narrative_id=narrative_id.delete("_in_place_editor")
      @narrative=Narrative.find(narrative_id)
      @patient=User.find_by_wedgetail(@narrative.wedgetail,:order =>"created_at DESC")
      authorize_only(:leader){@patient.firewall(@user)}
      authorize_only(:user){@patient.firewall(@user)}
      authorize :admin
      
      @item=Narrative.create(:wedgetail=>@patient.wedgetail,:narrative_type_id=>18,:content=>params[:value],:created_by=>@user.wedgetail,:content_type=>"text/plain",:condition_id=>@narrative.condition_id)
      render :text => CGI::escapeHTML(@item.content.to_s)
 
  end
  # GET /conditions
  # GET /conditions.xml
  def index
    
    @conditions = Condition.all
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
    end
      respond_to do |format|
        format.html{
          if !@patient or @patient.role!=5
            redirect_to :controller=>:patients, :action=>:index
          elsif ! @patient.hatched
            redirect_to :controller=>:patients, :action=>:unconfirmed
          end
          
        }  
      end
      # format.xml  { render :xml => @conditions }
   
  end

  # GET /conditions/1
  # GET /conditions/1.xml
  def show
    # before filter = getPatient
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
    end
    @condition = Condition.find(params[:id])
    
    #get condition summary
    
   unless @summary=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=18 and condition_id=?",params[:wedgetail],@condition.id], :order=>"narrative_date DESC,created_at DESC")

     
      #we need to create a new summary even if blank as the patient wedgetail is not passed with the AJAX in_line_edit call
      @summary=Narrative.create(:wedgetail=>params[:wedgetail],:narrative_type_id=>18,:condition_id=>@condition.id,:content=>"",:content_type=>"text/plain")
      
    end
    @summary.content="Click to add history of "+@condition.name if @summary.content==""
    
 
    @wall=Narrative.find(:all, :conditions=>["narrative_type_id!=18 and wedgetail=? and condition_id=?",params[:wedgetail],@condition.id], :order=>"narrative_date DESC,created_at DESC") 
 
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @condition }
    end
  end

  # GET /conditions/new
  # GET /conditions/new.xml
  def new
    @condition = Condition.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @condition }
    end
  end

  # GET /conditions/1/edit
  def edit
    @condition = Condition.find(params[:id])
  end

  # POST /conditions
  # POST /conditions.xml
  def create
    @condition = Condition.new(params[:condition])

    respond_to do |format|
      if @condition.save
        flash[:notice] = 'condition was successfully created.'
        format.html { redirect_to(@condition) }
        format.xml  { render :xml => @condition, :status => :created, :location => @condition }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @Condition.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /conditions/1
  # PUT /conditions/1.xml
  def update
    @condition = Condition.find(params[:id])

    respond_to do |format|
      if @Condition.update_attributes(params[:condition])
        flash[:notice] = 'condition was successfully updated.'
        format.html { redirect_to(@condition) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @Condition.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /conditions/1
  # DELETE /conditions/1.xml
  def destroy
    @condition = Condition.find(params[:id])
    @Condition.destroy

    respond_to do |format|
      format.html { redirect_to(conditions_url) }
      format.xml  { head :ok }
    end
 end
 
 def toggle
   render :update do |page|
     page.visual_effect :toggle_blind, params[:div]
     page.toggle params[:div]+'_show',params[:div]+'_hide'
   end
 end
  
  private
      def getPatient
         if !params[:patient_id]
            @status="No patient id"
         else
           params[:wedgetail]=params[:patient_id]
           @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
           if !@patient or @patient.role!=5 or !@patient.hatched
             @status="Patient not found"
           else
             @status="OK"
           end
        end
      end
  
end
