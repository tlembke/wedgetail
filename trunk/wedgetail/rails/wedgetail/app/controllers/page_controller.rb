class PageController < ApplicationController


  def show
    @pageTitle="Wedgetail Pages"
    @all_menus=[]
    @all_pages=[]
    Dir.foreach(RAILS_ROOT + "/public/pages/"){|filename|
      if (filename!="." and filename !=".." and filename !="index.txt")
        @page={}
        @menu={}
        @page[:file]=filename.slice(0..-5)
        title=File.new(RAILS_ROOT + "/public/pages/"+filename).gets
        @page[:title]=title.gsub(/<\/?[^>]*>/, "")
        filename=filename.slice(0..-5)
        @page[:file]=filename
        @menu[:file]=filename
        @menu[:title]=filename.gsub("_"," ").capitalize
        @all_pages<< @page
        @all_menus<< @menu
      end
    }
    if (!params[:page])
      page_address="index.txt"
    else
      page_address=params[:page]+".txt"
    end
    
    if(page_address=="index.txt")
      @pageTitle="About Wedgetail"
    else
      title=File.new(RAILS_ROOT + "/public/pages/"+page_address).gets
      @pageTitle=title.gsub(/<\/?[^>]*>/, "")
    end

    @pageText=IO.read(RAILS_ROOT + "/public/pages/"+page_address)

  end
  
  
end
