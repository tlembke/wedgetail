class Goal < ActiveRecord::Base
  belongs_to :measure
  belongs_to :condition
  has_many :careroles
  has_many :tasks
  
  attr_accessor :universal #do new goals apply to other patients or just the one open.
  
  # goals that are generic are created with a blank patient field
  # when a goal is added to a patient, a new goal is created, copying all the details of the generic goal
  # the instance of a goal assigned to a patient has values in the patient and parent fields
  # generic goals taht are written bu admin have a blank team fieldm amd are available to all users
  # generic goals created by a non-admin user are available to all members of their team
  
  def task_options(team,patient)
    # generic tasks that are available for a goal assigned to a patient
   @all_tasks=Task.find(:all,:conditions=>["active=1 and (goal_id=?) and (team='' or team=0 or team=?)",self.parent,team])
   @options=[]
   @all_tasks.each do |task|
     @options<<[task.title,task.id] unless Task.find(:first,:conditions=>["patient=? and active=1 and parent=?",patient,task.id])
   end
   @options<<["Create a new action...",0]
  end
  
  def active_tasks
    @active_tasks=Task.find(:all,:conditions=>["goal_id=? and active=1",self.id])
  end

  
end
   