class MeasurevaluesController < ApplicationController
  # GET /measurevalues
  # GET /measurevalues.xml
  def index
    @measurevalues = Measurevalue.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @measurevalues }
    end
  end

  # GET /measurevalues/1
  # GET /measurevalues/1.xml
  def show
    @measurevalue = Measurevalue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @measurevalue }
    end
  end

  # GET /measurevalues/new
  # GET /measurevalues/new.xml
  def new
    @measurevalue = Measurevalue.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @measurevalue }
    end
  end

  # GET /measurevalues/1/edit
  def edit
    @measurevalue = Measurevalue.find(params[:id])
  end

  # POST /measurevalues
  # POST /measurevalues.xml
  def create
    @measurevalue = Measurevalue.new(params[:measurevalue])

    respond_to do |format|
      if @measurevalue.save
        flash[:notice] = 'Measurevalue was successfully created.'
        format.html { redirect_to(@measurevalue) }
        format.xml  { render :xml => @measurevalue, :status => :created, :location => @measurevalue }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @measurevalue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /measurevalues/1
  # PUT /measurevalues/1.xml
  def update
    @measurevalue = Measurevalue.find(params[:id])

    respond_to do |format|
      if @measurevalue.update_attributes(params[:measurevalue])
        flash[:notice] = 'Measurevalue was successfully updated.'
        format.html { redirect_to(@measurevalue) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @measurevalue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /measurevalues/1
  # DELETE /measurevalues/1.xml
  def destroy
    @measurevalue = Measurevalue.find(params[:id])
    @measurevalue.destroy

    respond_to do |format|
      format.html { redirect_to(measurevalues_url) }
      format.xml  { head :ok }
    end
  end
end
