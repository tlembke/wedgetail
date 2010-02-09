class ResultsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  before_filter :find_patient, :except=> [:create, :new]
  layout "standard"
  
  # GET /results
  # GET /results.xml
  def index
    @results = Result.find_all_by_wedgetail(@patient.wedgetail)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @results }
      format.yaml { render :text => @result.to_yaml} 
    end
  end

  # GET /results/1
  # GET /results/1.xml
  def show
    @result = Result.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @result } 
      format.yaml { render :text => @result.to_yaml} 
    end
  end

  # GET /results/new
  # GET /results/new.xml
  def new
    @result = Result.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @result }
    end
  end

  # GET /results/1/edit
  def edit
    @result = Result.find(params[:id])
  end

  # POST /results
  # POST /results.xml
  def create
    @result = Result.new(params[:result])
    respond_to do |format|
      if @result.save
        flash[:notice] = 'Result was successfully created.'
        format.html { redirect_to(patient_results_url(:patient_id=>@result.wedgetail,:id=>@result.id)) }
        format.xml  { render :xml => @result, :status => :created, :location => @result }
        format.yaml { render :text => @result.to_yaml} 
      else
        flash[:notice] = 'Result was not saved!'
        format.html { render :action => "new" }
        format.xml  { render :xml => @result.errors, :status => :unprocessable_entity }
        format.yaml { render :to_yaml => @result, :status => :created, :location => @result } 
      end
    end
  end

  # PUT /results/1
  # PUT /results/1.xml
  def update
    @result = Result.find(params[:id])

    respond_to do |format|
      if @result.update_attributes(params[:result])
        flash[:notice] = 'Result was successfully updated.'
        format.html { redirect_to(@result) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @result.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /results/1
  # DELETE /results/1.xml
  def destroy
    @result = Result.find(params[:id])
    @result.destroy

    respond_to do |format|
      format.html { redirect_to(results_url) }
      format.xml  { head :ok }
    end
  end
  
  private 
    def find_patient
      @wedgetail = params[:patient_id] 
      return(redirect_to(patients_url)) unless @wedgetail
      @patient = User.find_by_wedgetail(@wedgetail) 
    end 
  
end
