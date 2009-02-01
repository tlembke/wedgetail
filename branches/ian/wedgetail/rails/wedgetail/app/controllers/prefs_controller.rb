# for handling server preferences. Accessible by admin (role=1 or 2) only
class PrefsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"


  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  def index
    authorize :admin
    render :action=> 'show' if @authorized
  end

  def show
    authorize :admin
  end

  def edit
    authorize :admin
  end

  def update
    authorize :admin
    errors = Pref.update_attributes(params[:pref])
    if errors = {}
      flash[:notice] = 'Pref was successfully updated.'
      redirect_to :action => 'show'
    else
      flash[:prefs_errors] = errors
      render :action => 'edit'
    end
  end


end
