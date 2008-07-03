class ItemNumbersController < ApplicationController
  # GET /item_numbers
  # GET /item_numbers.xml
  def index
    @item_numbers = ItemNumber.find(:all)

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @item_numbers.to_xml }
    end
  end

  # GET /item_numbers/1
  # GET /item_numbers/1.xml
  def show
    @item_number = ItemNumber.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @item_number.to_xml }
    end
  end

  # GET /item_numbers/new
  def new
    @item_number = ItemNumber.new
  end

  # GET /item_numbers/1;edit
  def edit
    @item_number = ItemNumber.find(params[:id])
  end

  # POST /item_numbers
  # POST /item_numbers.xml
  def create
    @item_number = ItemNumber.new(params[:item_number])

    respond_to do |format|
      if @item_number.save
        flash[:notice] = 'ItemNumber was successfully created.'
        format.html { redirect_to item_number_url(@item_number) }
        format.xml  { head :created, :location => item_number_url(@item_number) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item_number.errors.to_xml }
      end
    end
  end

  # PUT /item_numbers/1
  # PUT /item_numbers/1.xml
  def update
    @item_number = ItemNumber.find(params[:id])

    respond_to do |format|
      if @item_number.update_attributes(params[:item_number])
        flash[:notice] = 'ItemNumber was successfully updated.'
        format.html { redirect_to item_number_url(@item_number) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @item_number.errors.to_xml }
      end
    end
  end

  # DELETE /item_numbers/1
  # DELETE /item_numbers/1.xml
  def destroy
    @item_number = ItemNumber.find(params[:id])
    @item_number.destroy

    respond_to do |format|
      format.html { redirect_to item_numbers_url }
      format.xml  { head :ok }
    end
  end
end
