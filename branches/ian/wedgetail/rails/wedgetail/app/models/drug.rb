require 'rexml/document'

class Drug < Code
  def javascript_line
    return "{typ:'drug',name:'#{name}',popup:null,values:'#{values['instr']} qty #{values['qty']} rpt #{values['rpt']}'}"
  end



  def gen_pdf(text,narr,pdf)
    author = User.find_by_wedgetail(narr.created_by,:order=>"created_at desc")
    patient = narr.user
    team = User.find_by_wedgetail(author.team,:order=>"created_at desc")
    text.sub!(/qty:? *([0-9]+)(|ml|g) *rpt:? *([0-9]+)/i,"\nAmount: \\1 Repeats: \\3")
    text.sub!(/auth(ority)?:? ?([0-9a-zA-Z]+)/i,"\nAuthority: \\1")
    [0,105].each do |x|
      pdf.SetXY(x+25,21)
      pdf.Cell(70,6,author.prescriber)
      pdf.SetXY(x+24,53)
      pdf.Cell(70,6,patient.full_name)
      pdf.SetXY(x+24,58)
      pdf.MultiCell(70,5,patient.full_address)
      pdf.SetXY(x+10,68)
      pdf.Cell(80,6,narr.created_at.strftime("%d/%m/%Y"))
      unless text =~ /non\-?pbs/i
        unless patient.dva.blank?
          pdf.SetXY(x+23,35)
          pdf.Cell(75,6,patient.dva)
          pdf.SetXY(x+28,72)
        else
          pdf.SetXY(x+10,72)
        end
        pdf.Cell(8,6,"X",0,0,"L")
      end
      pdf.SetXY(x+25,90)
      pdf.MultiCell(65,5,name)
      pdf.SetXY(x+30,95)
      pdf.MultiCell(60,5,text+"\n\n\n\n"+author.full_name,0,"L")
    end      
  end


  def can_print?(text,narr)
    # FIXME: should validate text at this point
    true
  end

  def remaining(text,narr)
    # try to compute quantity remaining. 0 means run out, -1 means can't compute
    return -1 unless text =~ /qty:? *([0-9]+)(|ml|g) *rpt:? *([0-9]+)/i
    qty = $1.to_i
    rpt = $3.to_i
    unit = $2
    total = qty*(rpt+1)
    return -1 unless text =~ /([0-9\.]*) ?#{unit} ?(mane|nocte|bd|bid|tds|tid|qid|qds|od|daily)/
    if $1.blank?
      dose = 1
    else
      dose = $1.to_i
    end
    case $2
      when "od","mane","nocte","daily"
      dose = dose
      when "bd","bid"
      dose *= 2
      when "tds","tid"
      dose *= 3
      when "qid","qds"
      dose *= 4
    end
    days_ago = (Time.now-narr.created_at)/3600/24
    remaining = total - (days_ago*dose).to_i
    remaining = 0 if remaining < 0
    return remaining
  end


  def to_yaml
    x = {"code"=>code,"name"=>name,"items"=>values["items"]}
    x.to_yaml
  end

  def self.process_pbs
    dir = File.join(File.dirname(__FILE__),"../../db/migrate/codes_data")
    xmlzipfile = Dir.glob(File.join(dir,"G2B*.zip")).sort[-1]
    system("unzip -o \"#{xmlzipfile}\" -d #{dir}")
    xmlfile = xmlzipfile[0..-4]+"xml"
    extzipfile = Dir.glob(File.join(dir,"*Extracts.zip")).sort[-1]
    system("unzip -o \"#{extzipfile}\" -d #{dir}")
    drugfile = Dir.glob(File.join(dir, "drug*.txt")).sort[-1]
    dosesfile = File.join(dir,"doses.txt")
    doses = {}
    File.open(dosesfile).each_line do |line|
      l = line.split(':')
      doses[l[0]] = l[1].strip
    end
    auths = {}
    doc = REXML::Document.new(File.new(xmlfile))
    doc.elements.each('pbs:root/pbs:publication-layouts-list/pbs:publication-layout/pbs:section/pbs:listings-list/pbs:authority-required') do |elem|
      item = nil
      authlist = []
      elem.elements.each('pbs:code') {|e2| item = e2.text}
      elem.elements.each('pbs:indications-list/pbs:indication') do |e3|
        code = nil
        streamlined = false
        text = ""
        e3.elements.each('pbs:code') {|e4| code = e4.text}
        e3.elements.each('db:para/pbs:authority-method') {|e5| streamlined = e5.text.ends_with?("no-contact") }
        e3.elements.each('db:para') do |e6|
          if e6.attributes['role'] != "legal"
            text << e6.text+"\n"
          end
        end
        authlist << {"text"=>text,"streamlined"=>streamlined,"code"=>code}
      end
      auths[item] = authlist
    end
    drugs = {}
    File.new(drugfile).each_line do |line|
      line = line.split('!')
      trade = line[25].downcase
      generic = line[26].downcase
      generic.gsub!(" fumarate","")
      generic.gsub!(" hydrochloride","")
      form = line[27].strip.downcase
      atc = line[1]
      chapter = line[0]
      qty = line[8].to_f
      rpt = line[9].to_i
      item_no = line[4]
      flag = line[5]
      [generic,trade].each do |dname|
        unless dname =~ /terry white/ or dname =~ /^amcal/ or dname =~ /chem mart/ or dname =~ /genrx/ or (dname != generic and dname.include?(generic[0..7]))
          form.gsub!("tablet","tab")
          form.gsub!("capsule","cap")
          form.gsub!("dispersible","disp.")
          form.gsub!("(base)","")
          form.gsub!("(prolonged release)","SR")
          form.gsub!("(modified release)","SR")
          form.gsub!("(controlled release)","SR")
          form.gsub!(/equivalent to ([0-9]+) mg #{generic}( [a-z]+)?/,"\\1 mg")
          unless drugs[dname+form]
            d = Drug.new
            drugs[dname+form] = d
            d.name = dname+" "+form
            d.name.strip!
            d.code = atc
            d.values = {"items"=>{},"dose"=>"1 od"}
            doses.keys.each do |reg|
              d.values["dose"] = doses[reg] if Regexp.new(reg) =~ generic+" "+form
            end
          else
            d = drugs[dname+form]
          end
          d.values["items"][item_no] = {"qty"=>qty,"rpt"=>rpt,"chapter"=>chapter}
          if flag and auths.has_key?(item_no)
            d.values["items"][item_no]["auth"] = auths[item_no]
          end
        end
      end
    end
    drugs.values.each {|x| print x.to_yaml }
    #drugs.values.each {|x| x.save! }
  end
end
