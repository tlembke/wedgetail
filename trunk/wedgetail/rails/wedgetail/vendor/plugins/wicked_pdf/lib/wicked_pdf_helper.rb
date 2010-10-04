module WickedPdfHelper
  def wicked_pdf_stylesheet_link_tag style
    if params[:debug]=="1"
        stylesheet_link_tag style
    else
        stylesheet_link_tag "#{RAILS_ROOT}/public/stylesheets/#{style}"
    end
  end
end
