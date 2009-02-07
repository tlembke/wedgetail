class SubNarrative
  
  def initialize(code,text,narr)
    @code = code
    @text = text
    @narr = narr
    raise WedgieError, "can't link to abstract Code" if @code.class.name == "Code"
  end

  def method_missing(method,*args) 
    @code.send(method,@text,@narr,*args)
  end

  def code_class
    @code.class
  end

  def text
    @text
  end
  
  def narr
    @narr
  end

  def code
    @code.code
  end

  def name
    @code.name
  end
end

