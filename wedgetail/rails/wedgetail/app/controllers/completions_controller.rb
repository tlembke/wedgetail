class CompletionsController < ApplicationController


  def script
    @completions = Code.all_codes.values.delete_if {|c| c.class == Code}
    latest = "2000-1-1 00:00:00".to_time
    @completions.each do |c|
      latest = c.created_at if c.created_at > latest
      latest = c.updated_at if c.updated_at and c.updated_at > latest
    end
    render :content_type=>'text/javascript' if stale?(:etag=>@completions,:last_modified=>latest)
  end

  def code_value # JSON function to return value and comment associated with a code
    patient = User.find_by_wedgetail(params[:wedgetail],:order=>"created_by DESC")
    code = Code.find_by_name(params[:code])
    headers["Content-Type"] = "application/json"
    render :text=>code.get_text(patient).to_json
  end

end
