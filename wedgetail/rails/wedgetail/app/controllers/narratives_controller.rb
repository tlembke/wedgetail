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
    @narrative = Narrative.find(params[:id])

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
    @narrative = Narrative.new(params[:narrative])
    @narrative.created_by=@user.wedgetail

    respond_to do |format|
      if @narrative.save
        flash[:notice] = 'Narrative was successfully created.'
        format.html { redirect_to(@narrative) }
        format.xml  { render :xml => @narrative, :status => :created, :location => @narrative }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @narrative.errors, :status => :unprocessable_entity }
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
