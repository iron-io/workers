## To add to your account
```
iron_worker upload https://github.com/iron-io/workers/blob/master/iron_freshbooks/freshbook.worker
```


## example payload for Freshbooks Turnkey Worker
```
{
   "account": '<insert>.freshbooks.com',
   "api_key": '<insert>',
   "to": '<insert>@gmail.com',
   "from": '<insert>@gmail.com',
   "password": '<insert>',
   "domain": "gmail.com",
   "subject": "Monthly Iron Freshbooks Report",
   "smtp_address": 'smtp.gmail.com',
   "port": 587,
   "authentication": 'plain',
   "days_ago":  7G::Client.new()
client.tasks.create('freshbook',   {
   :account => '<insert>.freshbooks.com',
   :api_key => '<insert>',
   :to => '<insert>@gmail.com',
   :from => '<insert>@gmail.com',
   :password => '<insert>',
   :domain => "gmail.com",
   :subject => "Monthly Iron Freshbooks Report",
   :smtp_address => 'smtp.gmail.com',
   :port => 587,
   :authentication => 'plain',
   :days_ago =>  7,
   :project_id => 45 #if none defined all projects will be included in email
   :grouping => true/false #optional advanced option
    }
)

# optional advanced options
   "grouping" : true/false 
   # groups entries by task ids found in notes /#\d+/
   # for example #23546
```

## create a scheduled task for worker in ruby 
(feel free to schedule tasks in the method of your choice curl/node/go/php/java)
```ruby
schedule =client.schedules.create('freshbook', {
   "account": '<insert>.freshbooks.com',
   "api_key": '<insert>',
   "to": '<insert>@gmail.com',
   "from": '<insert>@gmail.com',
   "password": '<insert>',
   "domain": "gmail.com",
   "subject": "Monthly Iron Freshbooks Report",
   "smtp_address": 'smtp.gmail.com',
   "port": 587,
   "authentication": 'plain',
   "days_ago":  7
 
   "project_id": 45
   "grouping" : true/false #optional advanced option
    }
``` 
## run single task in ruby

```ruby
require 'iron_worker_ng'
client = IronWorkerN  "project_id": 45
   "grouping" : true/false #optional advanced option
    },
    {:start_at => Time.now, :run_every => 604800}
 )
# 604800 = 1 week in seconds
```
available scheduler options
* run_every:  The amount of time, in seconds, between runs. By default, the task will only run once. will return a 400 error if it is set to less than 60.
* end_at:     The time tasks will stop being queued. Should be a time or datetime.
* run_times:  The number of times a task will run.
* priority:   The priority queue to run the job in. Valid values are 0, 1, and 2. The default is 0. Higher values means tasks spend less time in the queue once they come off the schedule.
* start_at:   The time the scheduled task should first be run

