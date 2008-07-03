# for management of patients and display of patient records and narratives
class RecordController < ApplicationController
     before_filter :redirect_to_ssl, :authenticate

      def index
        list
        render :action => 'list'
      end

      # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
      verify :method => :post, :only => [ :destroy, :create, :update ],
             :redirect_to => { :action => :list }

      # find patients according to search parameters
      def list
        authorize :user
        if params[:wedgetail].to_s!=""
            redirect_to :action => "show", :wedgetail => params[:wedgetail]
        elsif !(params[:family_name].to_s=="" && params[:given_names].to_s=="")
            @patients = User.paginate(:page => params[:page],:per_page => 10, :order => 'family_name,wedgetail DESC, created_at DESC', :conditions => ["visibility=? and family_name like ? and (given_names like ? or known_as like ?)", true,params[:family_name].to_s+"%",params[:given_names].to_s+"%",params[:given_names].to_s+"%"])
        end
      end

      # show all users who access a patient's information
      def audit
         @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
         authorize_only (:patient) {@patient.wedgetail == @user.wedgetail}
         authorize :user
         @audits = Audit.paginate(:page => params[:page],:per_page => 60, :order => 'created_at DESC', :conditions => ["patient=?", params[:wedgetail]])
      end  

      #main patient display
      def show
        @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
        if @patient.role!=5
          redirect_to :action => :list
        end
        if ! @patient
           flash[:notice]='Patient not found'
           redirect_to :action => :list
        elsif @patient.wedgetail.starts_with?("U")
           flash[:notice]='Patient not yet registered'
           render(:action=> :unconfirmed)
        else
          authorize_only(:patient) {@patient.wedgetail == @user.wedgetail}
          authorize_only(:temp) { @patient.wedgetail == @user.wedgetail.from(6)}
          authorize_only(:leader){@patient.firewall(@user)}
          authorize_only(:user){@patient.firewall(@user)}
          authorize :admin
          @narratives=Narrative.find(:all, :conditions=>["wedgetail=?",params[:wedgetail]], :order=>"created_at DESC")
          @audit=Audit.create(:patient=>params[:wedgetail],:user_wedgetail=>@user.wedgetail)
          @special=Array.new
          @count=Array.new
          @displayOrder=[1,2,5,3,4,8,7,9,6]
          j=1
          for i in @displayOrder
            @special[j]=Narrative.find(:first, :conditions=>["wedgetail=? and narrative_type_id=?",params[:wedgetail],i], :order=>"narrative_date DESC,created_at DESC") 
            @count[i]= Narrative.count(:all,:conditions=>["wedgetail='#{params[:wedgetail]}' and narrative_type_id='#{i}'"])
            j=j+1
          end
        end
        
      end

      #display narrative
      def narrative
        # if type defined, show all of that type
        # otherwise, show only specified narrative
        if params[:type]
          @narratives=Narrative.find(:all, :conditions=>["wedgetail=? and narrative_type_id=?",params[:id],params[:type]], :order=>"narrative_date DESC,created_at DESC")
          @narrativeType=NarrativeType.find(params[:type])
          @title=@narrativeType.narrative_type_name.pluralize
          @wedgetail=params[:id]
        else
          @narrative=Narrative.find(params[:id])
          @title=@narrative.narrative_type.narrative_type_name
          @wedgetail=@narrative.wedgetail
          @narratives=Array.new
          @narratives << @narrative
        end
        @patient=User.find_by_wedgetail(@wedgetail,:order =>"created_at DESC") 
        authorize_only (:patient) {@wedgetail == @user.wedgetail}
        authorize_only (:temp) {@wedgetail == @user.wedgetail.from(6)}
        authorize_only(:leader){@patient.firewall(@user)}
        authorize_only(:user){@patient.firewall(@user)}
        authorize :admin
        @audit=Audit.create(:patient=>@wedgetail,:user_wedgetail=>@user.wedgetail)
      end
      
      def new
        authorize :user
        @patient = User.new
      end

      # note that new patients are assigned a temporary wedgetail number
      # until their uniqueness is determined by the big wedgie,
      # who then 'hatches' them
      def create
        authorize :user
        @patient = User.new(params[:patient])
        # generate temporary wedgetail number
        wedgetail_number=WedgePassword.make("U")
        @patient.wedgetail=wedgetail_number
        @patient.username = @patient.wedgetail
        @patient.role=5
       	begin 
          @patient.save! 
          flash[:notice]='Patient saved'
          redirect_to :action => :show, :wedgetail => @patient.wedgetail 
      	rescue ActiveRecord::RecordInvalid => e 
          render :action => :new
        end
      end 
    
      def edit
        authorize :user
        @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC") 
      end

      def update
        authorize :user
        @patient = User.find_by_wedgetail(params[:patient][:wedgetail],:order =>"created_at DESC")
        @patient.update_attributes(params[:patient])
        if @patient.save
          flash[:notice] = 'Patient was successfully updated.'
          redirect_to :action => 'show', :wedgetail => @patient.wedgetail
        else
          render :action => 'edit'
        end
      end

      # the nest contains all 'unhatched' patient, awaiting confirmation by big wedgie
      def nest
        authorize :big_wedgie
        @patients=User.find(:all,:conditions=>["wedgetail LIKE ?","U%"], :order => "family_name,given_names")
      end

      def hatch
          authorize :big_wedgie
          new_wedgetail=params[:wedgetail] + ""
          new_wedgetail[0]='H'
          @new_patient=User.find_by_wedgetail(params[:wedgetail])
          @new_patient.wedgetail=new_wedgetail
          @new_patient.username=new_wedgetail
          @new_patient.save
          render :update do |page|
              page.replace_html "old_wedge_"+params[:wedgetail],new_wedgetail
              page.replace_html "hatch_"+params[:wedgetail],"<font color=red>Hatched</font>"

              page.replace_html 'sb_unhatched_count', "(" + User.unhatched.size.to_s + " unhatched)"
          end
      end    

      # if a user has registered an interest in a patient, they will receive a copy of all new narratives
      def register
          wedgetail = params[:wedgetail]
          @interest=Interest.create(:patient => wedgetail, :user =>@user.wedgetail)
           text=<<EOF
<a href="#" onclick="new Ajax.Request('/record/unregister/#{wedgetail}', 
{asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader" border="0" id="internet-news-reader" src="/images/icons/tango/large/internet-news-reader.png" valign="middle" />
<script>new Tip("internet-news-reader",
"You have been registered to receive HL7 updates on this patient. Click to unregister",{title:'Thanks for registering'});
</script></a>
EOF
          render :update do |page|
              page.replace_html "register",text
          end
      end
      
      def unregister
          wedgetail = params[:wedgetail]
          Interest.delete_all(["patient = '#{wedgetail}' and user='#{@user.wedgetail}'"])
          text=<<EOF
<a href="#" 
onclick="new Ajax.Request('/record/register/#{wedgetail}', {asynchronous:true, evalScripts:true}); return false;">
<img alt="Internet-news-reader-x" border="0" id="internet-news-reader-x" src="/images/icons/tango/large/internet-news-reader-x.png" valign="middle" />
<script>new Tip("internet-news-reader-x",
"You have been unregistered from receiving updates about this patient. Click to re-register.",{title:'Thanks for unregistering'});
</script></a>
EOF
          render :update do |page|
              page.replace_html "register", text
          end
      end 
           
      def new_message_patient
        @message=Message.new
         if(params[:recipient_id])
           @recipient_user=User.find(params[:recipient_id])
         end
        render :update do |page|
          page.visual_effect :toggle_blind, "new_message_patient"
        end
      end
      
      # guests have one time read only access to a particular patient
      def guests
        @patient=User.find_by_wedgetail(params[:wedgetail],:order =>"created_at DESC")
        if params[:commit]=="Save changes"
          @thisguest=User.find_by_username(params[:user][:username])
          @thisguest.update_attributes(:family_name=>params[:user][:family_name],:given_names=>params[:user][:given_names])
        end 
        @guests=User.find(:all,:conditions=>["wedgetail LIKE ? and wedgetail !=?","%"+ params[:wedgetail],params[:wedgetail]])
      end
      
      # generates the consent for new patients, text found in /public/consent.txt
      def consent
        send_data(gen_pdf(params[:wedgetail]), :filename => "consent.pdf", :type => "application/pdf")
      end

      def gen_pdf(wedgetail)
        patient=User.find_by_wedgetail(wedgetail,:order =>"created_at DESC")
        patient_name=patient.full_name + "\n"
        patient_text="DOB - "+patient.dob.day.to_s + "/" + patient.dob.month.to_s + "/" + patient.dob.year.to_s + "\n"
        patient_text+= patient.address_line + "\n" + patient.town + "\n\n\n"
        consent_text= IO.read(RAILS_ROOT + "/public/consent.txt") 
        consent_text=consent_text.sub("<patient_full_name>",patient_name)


        pdf=FPDF.new
        pdf.AddPage
        pdf.SetFont('Arial','B',16)
        #a0aeb9
        pdf.SetFillColor(160,174,185)
        pdf.Image(RAILS_ROOT + '/public/images/wedgetail_little.jpg', 10, 8, 30)
        pdf.SetX(50)
        pdf.Cell(130,10,'Wedgetail Shared Electronic Health Record',1,1,'C',1)
        pdf.SetX(55)
        pdf.Cell(100,10,'Patient Consent Form',0 ,1,'C');
        pdf.SetX(30)
        pdf.SetY(55)
        pdf.SetFillColor(204)
        pdf.SetDrawColor(0,0,0)
        pdf.Rect(10,53,100,25,"DF")
        pdf.SetFont('Arial','B',16)
        pdf.Write(5,patient_name)
        pdf.SetFont('Arial','',12)
        pdf.Write(5,patient_text)
        pdf.Write(5,consent_text)
        pdf.Output 
      end
  

end
