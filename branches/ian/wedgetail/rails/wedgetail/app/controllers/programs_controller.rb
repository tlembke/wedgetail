class ProgramsController < ApplicationController

  # GET /programs/1
  # GET /programs/1.xml
  def show
    @condition = Condition.find(params[:id])
    @consultations=Consultation.find_by_condition_id(:all,params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @condition.to_xml }
    end
  end
  
end
