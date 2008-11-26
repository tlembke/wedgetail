class TextForm < Form
  @@contents = ""
  
  def TextForm.setup(filename)
    @@contents = File.new(filename).read
  end
 
end