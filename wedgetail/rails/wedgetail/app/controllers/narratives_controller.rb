class NarrativesController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"
  # GET /narratives
  # GET /narratives.xml
  def index
    @narratives = Narrative.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @narratives }
    end
  end

  # GET /narratives/1
  # GET /narratives/1.xml
  def show
    # if type defined, show all of that type
    # otherwise, show only specified narrative
    if params[:type]
      @narratives=Narrative.find(:all, :conditions=>["wedgetail=? and narrative_type_id=?",params[:id],params[:type]], :order=>"narrative_date DESC,created_at DESC")
      @narrativeType=NarrativeType.find(params[:type])
      @title=@narrativeType.narrative_type_name.pluralize
      @wedgetail=params[:id]
    else
      @narrative=Narrative.find(params[:id])
      @narrative.narrative_type_id=14 unless @narrative.narrative_type_id
      @title=@narrative.narrative_type.narrative_type_name
      @wedgetail=@narrative.wedgetail
      @narratives=Array.new
      @narratives << @narrative
    end
    @patient=User.find_by_wedgetail(@wedgetail,:order =>"created_at DESC") 
    authorize_only (:patient) {@wedgetail == @user.wedgetail}
    authorize_only (:temp) {@wedgetail == @user.wedgetail.from(6)}
    authorize_only(:leader){@patient.firewall(@user)}
    authorize_only(:user){@patient.firewall(@user)}
    authorize :admin
    @audit=Audit.create(:patient=>@wedgetail,:user_wedgetail=>@user.wedgetail)
    OutgoingMessage.check_view(@user,@narrative) if @narrative

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @narrative }
    end
  end

  # GET /narratives/new
  # GET /narratives/new.xml
  def new
    @narrative = Narrative.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @narrative }
    end
  end

  # GET /narratives/1/edit
  def edit
    @narrative = Narrative.find(params[:id])
  end

  # POST /narratives
  # POST /narratives.xml
  def create
    authorize :user
    failflag=""
    
    if params[:narrative][:localID]
      @localID=params[:narrative][:localID]
      params[:narrative].delete("localID")
      unless params[:narrative][:wedgetail]
        #wedgetail not specified so need to find
        if @localmap=Localmap.get(@user,@localID)
          #patient with that localID exists - good.Get wedgetail
          @wedgetail=@localmap.wedgetail
        else
          # no localmap so can't create narrative
          failflag="Error 1: No map for specified localID"
        end
      end
    end
    if failflag==""
      @narrative = Narrative.new(params[:narrative])
      @narrative.created_by=@user.wedgetail
      if @wedgetail
        @narrative.wedgetail=@wedgetail
      end
      unless User.find_by_wedgetail(@narrative.wedgetail) 
        failflag="Error 2:Patient with that wedgetail not found"
      end
    end
    
    respond_to do |format|
      if failflag=="" and @narrative.save
        flash[:notice] = 'Narrative was successfully created.'
        @message="Narrative created"
         @narratives=[@narrative]
        format.html { redirect_to(@narrative) }
        format.xml  { render :xml => @narratives, :template => 'narratives/narratives.xml.builder',:status => :created }
      else
        @message=failflag
        @narratives=[@narrative]
        format.html { render :action => "new" }
        format.xml  { render :xml => @narratives, :template => 'narratives/narratives.xml.builder', :status => :unprocessable_entity }
      end
    end
  end

  # PUT /narratives/1
  # PUT /narratives/1.xml
  def update
    @narrative = Narrative.find(params[:id])

    respond_to do |format|
      if @narrative.update_attributes(params[:narrative])
        flash[:notice] = 'Narrative was successfully updated.'
        format.html { redirect_to(@narrative) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @narrative.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /narratives/1
  # DELETE /narratives/1.xml
  def destroy
    @narrative = Narrative.find(params[:id])
    @narrative.destroy

    respond_to do |format|
      format.html { redirect_to(narratives_url) }
      format.xml  { head :ok }
    end
  end
end
