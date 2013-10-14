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
  attr_writer :hours

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
  attr_accessor :fresh_client, :time_entry_task_ids, :projects,
  :contractors, :time_entries, :time_hash, :project_time_totals,
  :time_hash, :project_staff_totals

  def initialize(account, api, days_ago=7, grouping=false)
    @days_ago = days_ago
    @fresh_client = initialize_client(account, api)
    @projects = project_setup
    @contractors = contractor_setup
    @time_entries = time_setup
    @time_hash = Hash.new {|hsh, key| hsh[key] = [] }
    @time_entry_task_ids = Hash.new {|hsh, key| hsh[key] = [] }
    time_sort
    if grouping
      group_time_by_ids
      generate_project_time_totals_grouped
      generate_project_staff_total_grouped
    else
      generate_project_time_totals
      generate_project_staff_total
    end
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

  def group_time_by_ids
    @time_hash.each do |key, time_entries_array|
      time_entries_array.each do |time_entry|
        if time_entry.notes
          scanned = time_entry.notes.scan(/#\d+/)
          if scanned.length > 1
            scanned.each do |some_id|
              time_entry.hours = (time_entry.hours.to_f.round(3) / scanned.length).to_s
            @time_entry_task_ids[some_id] << time_entry
            end
          else
            scanned.each do |some_id|
            @time_entry_task_ids[some_id] << time_entry
            end
          end
        end
        if time_entry.notes.scan(/#\d+/).empty?
          @time_entry_task_ids["the below entries have no task #id detected"] << time_entry
        end
      end
      @time_hash[key] = @time_entry_task_ids
    end
  end

def time_sort
  @time_entries.each do |entry|
    @time_hash[entry.project_name] << entry
  end
  @time_hash
end

def generate_project_time_totals_grouped
  @project_time_totals = Hash.new(0)
  @time_hash.each do |project_name, hash_by_sorted_id|
    hash_by_sorted_id.each do |key, time_entries|
      time_entries.each do |entry|
        @project_time_totals[project_name] += entry.hours.to_f
      end
    end
  end
end

def generate_project_staff_total_grouped
  @project_staff_totals = Hash.new {|hsh, key| hsh[key] = Hash.new(0) }
  @time_hash.each do |project_name, hash_by_sorted_id|
    hash_by_sorted_id.each do |key, time_entries|
      time_entries.each do |entry|
        @project_staff_totals[project_name][entry.staff_name] += entry.hours.to_f
      end
    end
  end
  @project_staff_totals.each do  |project_name, employee_hash|
    employee_hash.each do |name, hours|
      employee_hash[name] = convert_hours(hours)
    end
  end
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

report = Report.new(params['account'], params['api_key'], params["days_ago"], params["grouping"])

if params["project_id"] == nil
  @report_project_time_totals = report.project_time_totals
  @project_staff_totals = report.project_staff_totals
  @time_hash = report.time_hash
else
  @selector                   = report.projects.select { |project| project.id == params["project_id"].to_s}
  if @selector.any?
    @selector = @selector.first.name
  else
    @selector = "No Project Found - Please Revise Project ID"
  end
  @time_hash = report.time_hash.select {|project_name, task_id| project_name == @selector}
  @report_project_time_totals = report.project_time_totals.select {|project_name, total| project_name == @selector}
  @project_staff_totals       = report.project_staff_totals.select {|project_name, staff_totals| project_name == @selector}
  @no_projects = true if @project_staff_totals.empty? & @report_project_time_totals.empty?
end

@subject = params["subject"]

if @no_projects == true 
  renderer = ERB.new(File.read("template_no_data.erb"))
elsif params["grouping"]
  renderer = ERB.new(File.read("template_grouping.erb"))
else
  renderer = ERB.new(File.read("template_standard.erb"))
end
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
              message_details = send_mail(email, params['from'], @subject, "#{output}")
              puts "message_details: " + message_details.inspect
            end
            puts "IronFreshbooks Worker finished"
