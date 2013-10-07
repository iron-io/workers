
To add to your account
```
iron_worker upload https://github.com/iron-io/workers/blob/master/iron_freshbooks/freshbook.worker
```


example payload for Freshbooks Turnkey Worker
```
{
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
   :days_ago =>  7
    }
``` 
run task in ruby
```ruby
require 'iron_worker_ng'
client = IronWorkerNG::Client.new()
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
   :days_ago =>  7
    }
)
```
