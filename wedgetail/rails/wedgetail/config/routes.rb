ActionController::Routing::Routes.draw do |map|
  map.resources :localmaps, :only => [:create, :index, :logincheck], :collection => { :logincheck => :get }

  map.resources :actions, :only => [:index,:show,:create]

  map.resources :result_tickets, :only => [:create], :collection => { :check => :post } 

  map.resources :users

  map.resources :patients, :key => :wedgetail, :has_many => :narratives
  

  
  map.resources :results, :only => [:create, :new]
  
  

  map.resources :narratives

  map.resources :item_numbers

  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.

                                        

 
 map.connect '', :controller => 'patients', :action => 'index'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  
  map.connect 'page/:page/',
              :controller => "page",
              :action => "show"
  map.connect 'page',
              :controller => "page",
              :action => "show"  
  map.connnect 'record/narrative/:id',
              :controller => "record",
              :action => "narrative"
  map.connect 'entry/gen_pdf/:id',
              :controller=>'entry',:action=>'gen_pdf'
  map.connnect 'messages/:action/:id',
              :controller => "messages"
  map.connnect 'prefs/:action/:id',
              :controller => "prefs"
  map.connect 'rest/:action/:id',
              :controller => "rest"
  map.connect 'rest/:action/:id/:id2',
              :controller => "rest"
  map.connnect 'ajax/:action/:id',
              :controller => "ajax"
 map.connnect 'consultations/:action/:id',
              :controller => "consultations"

  map.connect ':controller/:action/:wedgetail'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action'
  
end
