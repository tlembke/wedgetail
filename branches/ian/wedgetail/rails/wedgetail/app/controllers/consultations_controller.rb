class ConsultationsController < ApplicationController

  
  def index
    @consultations = Consultation.find(:all)
  end

  def show
    @consultation = Consultation.find(params[:id])
  end

  def new
    @consultation = Consultation.new
    @items=ItemNumber.find(:all)
  end

  def edit
    @consultation = Consultation.find(params[:id])
    @items=ItemNumber.find(:all)
  end

  # GET /consultations/1;activities
  def activities
    @consultation = Consultation.find(params[:id])
    @user=@consultation
    @all=Activity.find(:all)
    @pending_todos=[]
    @completed_todos=@consultation.activities
    for each_act in @all
      if not @completed_todos.include? each_act
        @pending_todos << each_act
      end
    end
  end

  def create
    @consultation = Consultation.new(params[:consultation])
    @consultation.item_numbers=ItemNumber.find(params[:item_ids]) if params[:item_ids]
    respond_to do |format|
      if @consultation.save
        flash[:notice] = 'Consultation was successfully created.'
        format.html { redirect_to consultation_url(@consultation) }
        format.xml  { head :created, :location => consultation_url(@consultation) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @consultation.errors.to_xml }
        @items=ItemNumber.find(:all)
      end
    end
  end

  def update
    @consultation = Consultation.find(params[:id])
    @consultation.item_numbers=ItemNumber.find(params[:item_ids]) if params[:item_ids]

      if @consultation.update_attributes(params[:consultation])
        flash[:notice] = 'Consultation was successfully updated.'
        redirect_to :action=>:show, :id=>@consultation 

      else
        @items=ItemNumber.find(:all)
      end

  end


  def destroy
    @consultation = Consultation.find(params[:id])
    @consultation.destroy

  end
end
