class CarerolesController < ApplicationController
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
  # GET /careroles
  # GET /careroles.xml  
  def index
    @careroles = Carerole.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @careroles }
    end
  end

  # GET /careroles/1
  # GET /careroles/1.xml
  def show
    @carerole = Carerole.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @carerole }
    end
  end

  # GET /careroles/new
  # GET /careroles/new.xml
  def new
    @carerole = Carerole.new
    @crafts=Craft.find(:all)
    @goals=Goal.find(:all,:conditions=>["parent=0"])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @carerole }
    end
  end

  # GET /careroles/1/edit
  def edit
    @carerole = Carerole.find(params[:id])
    @crafts=Craft.find(:all)
    @goals=Goal.find(:all,:conditions=>["parent=0"])
  end

  # POST /careroles
  # POST /careroles.xml
  def create
    
    @carerole = Carerole.new(params[:carerole])

    respond_to do |format|
      if @carerole.save
        flash[:notice] = 'Carerole was successfully created.'
        format.html { redirect_to(@carerole) }
        format.xml  { render :xml => @carerole, :status => :created, :location => @carerole }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @carerole.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /careroles/1
  # PUT /careroles/1.xml
  def update
    @carerole = Carerole.find(params[:id])

    respond_to do |format|
      if @carerole.update_attributes(params[:carerole])
        flash[:notice] = 'Carerole was successfully updated.'
        format.html { redirect_to(@carerole) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @carerole.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /careroles/1
  # DELETE /careroles/1.xml
  def destroy
    @carerole = Carerole.find(params[:id])
    @carerole.destroy

    respond_to do |format|
      format.html { redirect_to(careroles_url) }
      format.xml  { head :ok }
    end
  end
end
