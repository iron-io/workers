require 'ruby-freshbooks'
require 'mail'
require 'erb'

class Contractor

  attr_reader :id, :name, :email, :status, :rate, :task_id, :projects

  def initialize(args)
    @id = args["contractor_id"]
    @name = args["name"]
    @email = args["email"]
    @status = args["status"]
    @rate = args["rate"]
    @task_id = args["task_id"]
    @projects = args["projects"]
  end

end

class Project

  attr_reader :id, :name

  def initialize(args)
    @id = args["project_id"]
    @name = args["name"]
  end

end


class TimeEntry
  attr_reader :time_entry_id, :staff_id ,:project_id, :task_id, :hours, :date, :notes, :billed, :project_name, :staff_name

  def initialize(args)
    @time_entry_id = args["time_entry_id"]
    @staff_id      = args["staff_id"     ]
    @project_id    = args["project_id"   ]
    @task_id       = args["task_id"      ]
    @hours         = args["hours"        ]
    @date          = args["date"         ]
    @notes         = args["notes"        ]
    @billed        = args["billed"       ]
    @project_name  = args["project_name"]
    @staff_name = args["staff_name"]
  end
end

class Report
  attr_accessor :projects, :contractors, :time_entries, :time_hash, :project_time_totals, :time_hash, :project_staff_totals

  def initialize(account, api, days_ago=7)
    @days_ago = days_ago
    @fresh_client = initialize_client(account, api)
    @projects = project_setup
    @contractors = contractor_setup
    @time_entries = time_setup
    @time_hash = Hash.new {|hsh, key| hsh[key] = [] }
    time_sort
    generate_project_time_totals
    generate_project_staff_total
  end

  def initialize_client(account, api)
    FreshBooks::Client.new(account, api)
  end

  def contractor_setup
    @fresh_client.contractor.list["contractors"]["contractor"].map do |params|
      unless params.nil?
        Contractor.new(params)
      end
    end
  end

  def project_setup
    @fresh_client.project.list["projects"]["project"].map do |params|
      Project.new(params)
    end
  end

  def time_setup
    @fresh_client.time_entry.list(:per_page => 100)["time_entries"]["time_entry"].map do |entry|
      if Date.parse(entry["date"]) > Date.today - @days_ago
        entry["project_name"] = @projects.find {|project| project.id == entry["project_id"]}.name
        staff = @contractors.find {|contractor| contractor.id == entry["staff_id"]}
        if staff
          entry["staff_name"] = staff.name
        else
          entry["staff_name"] = "Name N/A or Not Found"
        end
        TimeEntry.new(entry)
      end
    end.compact!.sort_by { |entry| entry.project_name}
  end

  def time_sort
    @time_entries.each do |entry|
      @time_hash[entry.project_name] << entry
    end
    @time_hash
  end

  def generate_project_time_totals
    @project_time_totals = Hash.new(0)
    @time_hash.each do |project_name, entries|
      entries.each do |entry|
        @project_time_totals[project_name] += entry.hours.to_f
      end
    end
  end

  def generate_project_staff_total
    @project_staff_totals = Hash.new {|hsh, key| hsh[key] = Hash.new(0) }

    @time_hash.each do |project_name, entries|
      entries.each do |entry|
        @project_staff_totals[project_name][entry.staff_name] += entry.hours.to_f
      end
    end
    @project_staff_totals.each do  |project_name, employee_hash|
      employee_hash.each do |name, hours|
        employee_hash[name] = convert_hours(hours)
      end
    end
  end

  def convert_hours(hours)
    minutes = hours *=60
    hh, mm = minutes.divmod(60)
    "%d hours, %d minutes" % [ hh, mm]
  end
end

################ end class definitions ##############

report = Report.new(params['account'], params['api_key'], params["days_ago"])
@time_hash = report.time_hash
@report_project_time_totals = report.project_time_totals
@project_staff_totals = report.project_staff_totals
renderer = ERB.new(File.read("template.erb"))
output = renderer.result()


# Configures smtp settings to send email.
def init_mail
  puts "Preparing mail configuration"
  mail_conf = {:address => params['smtp_address'],
               :port => params['port'],
               :domain => params['domain'],
               :user_name => params['from'],
               :password => params['password'],
               :authentication => params['authentication'],
               :enable_starttls_auto => true } #gmail requires this option
               Mail.defaults do
                delivery_method :smtp, mail_conf
              end
              puts "Mail service configured"
            end

            def send_mail(to, from, subject, content)
              puts "Preparing email from: #{from}, to: #{to}, subject: #{subject}"
              msg = Mail.new do
                to to
                from from
                subject subject
                html_part do |m|
                  content_type 'text/html'
                  body content
                end
              end
              puts "Mail ready, delivering"
              details = msg.deliver
              puts "Mail delivered!"
              details
            end

puts "IronFreshbooks Worker started"
init_mail
to = Array(params['to'])

to.each do |email|
  message_details = send_mail(email, params['from'], params["subject"], "#{output}")
  puts "message_details: " + message_details.inspect
end
puts "IronFreshbooks Worker finished"