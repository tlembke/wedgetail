class ConditionsController < ApplicationController
  # GET /conditions
  # GET /conditions.xml
  def index
    @conditions = Condition.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @conditions.to_xml }
    end
  end

  # GET /conditions/1
  # GET /conditions/1.xml
  def show
    @condition = Condition.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @condition.to_xml }
    end
  end

  # GET /conditions/new
  def new
    @condition = Condition.new
  end

  # GET /conditions/1;edit
  def edit
    @condition = Condition.find(params[:id])
  end

  # POST /conditions
  # POST /conditions.xml
  def create
    @condition = Condition.new(params[:condition])

    respond_to do |format|
      if @condition.save
        flash[:notice] = 'Condition was successfully created.'
        format.html { redirect_to condition_url(@condition) }
        format.xml  { head :created, :location => condition_url(@condition) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @condition.errors.to_xml }
      end
    end
  end

  # PUT /conditions/1
  # PUT /conditions/1.xml
  def update
    @condition = Condition.find(params[:id])

    respond_to do |format|
      if @condition.update_attributes(params[:condition])
        flash[:notice] = 'Condition was successfully updated.'
        format.html { redirect_to condition_url(@condition) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @condition.errors.to_xml }
      end
    end
  end

  # DELETE /conditions/1
  # DELETE /conditions/1.xml
  def destroy
    @condition = Condition.find(params[:id])
    @condition.destroy

    respond_to do |format|
      format.html { redirect_to conditions_url }
      format.xml  { head :ok }
    end
  end
end
