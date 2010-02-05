class StatsController < ApplicationController
  before_filter :redirect_to_ssl, :authenticate
  layout "standard"
  # :big_wedgie=>1,:admin=>2,:leader=>3,:user=>4,:patient=>5
  def index
      @stats={:patients=>User.count(:conditions =>"role=5"),
              :users=>User.count(:conditions =>"role<5"),
              :audits=>Audit.count,
              :audits_week=>Audit.count(:conditions => ['created_at > ?', 1.week.ago]),
              :audits_month=>Audit.count(:conditions => ['created_at > ?', 1.month.ago]),
              :audits_last_week=>Audit.count(:conditions => ['created_at < ? and created_at >?', 1.week.ago, 2.weeks.ago]),
              :audits_last_month=>Audit.count(:conditions => ['created_at < ? and created_at >?', 1.month.ago, 2.months.ago]),
              :result_tickets=>ResultTicket.count,
              :result_tickets_week=>ResultTicket.count(:conditions => ['created_at > ?', 1.week.ago]),
              :result_tickets_month=>ResultTicket.count(:conditions => ['created_at > ?', 1.month.ago]),
              :result_tickets_last_week=>ResultTicket.count(:conditions => ['created_at < ? and created_at >?', 1.week.ago, 2.weeks.ago]),
              :result_tickets_last_month=>ResultTicket.count(:conditions => ['created_at < ? and created_at >?', 1.month.ago, 2.months.ago]),
              :results=>Result.count,
             }
     
  end
end
