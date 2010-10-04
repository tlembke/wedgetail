class CraftsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"
  
  # GET /crafts
  # GET /crafts.xml
  def index
    @crafts = Craft.all
    @cg = [ '','Doctor', 'Allied Health', 'Nursing', 'Admin' ]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @crafts }
    end
  end

  # GET /crafts/1
  # GET /crafts/1.xml
  def show
    @craft = Craft.find(params[:id])
    @cg = [ '','Doctor', 'Allied Health', 'Nursing', 'Admin' ]
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @craft }
    end
  end

  # GET /crafts/new
  # GET /crafts/new.xml
  def new
    @craft = Craft.new
    @craftgroups=Craft.get_craftgroups
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @craft }
    end
  end

  # GET /crafts/1/edit
  def edit
    @craft = Craft.find(params[:id])
    @craftgroups=Craft.get_craftgroups
  end

  # POST /crafts
  # POST /crafts.xml
  def create
    @craft = Craft.new(params[:craft])
    respond_to do |format|
      if @craft.save
        flash[:notice] = 'Craft was successfully created.'
        format.html { redirect_to(:action=>'index') }
        format.xml  { render :xml => @craft, :status => :created, :location => @craft }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @craft.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /crafts/1
  # PUT /crafts/1.xml
  def update
    @craft = Craft.find(params[:id])

    respond_to do |format|
      if @craft.update_attributes(params[:craft])
        flash[:notice] = 'Craft was successfully updated.'
        format.html { redirect_to(@craft) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @craft.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /crafts/1
  # DELETE /crafts/1.xml
  def destroy
    @craft = Craft.find(params[:id])
    @craft.destroy

    respond_to do |format|
      format.html { redirect_to(crafts_url) }
      format.xml  { head :ok }
    end
  end
  
  def get_craftgroups
    @cg = [ 'Doctor', 'Allied Health', 'Nursing', 'Admin' ]
    @option_string=""
    count=1
    @cg.each do |option|
      @option_string=@option_string+"<option value='" + count.to_s
      @option_string=@option_string +"'>"+ option +"</option>"
      count=count+1
    end  
    return @option_string
  end
  

end
