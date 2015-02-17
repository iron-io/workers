require 'pandoc-ruby'
require "httparty"
  # slightly unsure if Pandoc Ruby works correctly
  # PandocRuby.bin_path = "/usr/local/bin"


@params
@config
ENV
@task_id

# read contents of file save into response variable
response = HTTParty.get(params["file_location"])
# setup conversion
@doc = PandocRuby.new(response, :from => params["original_type"].to_sym, :to => params["new_type"].to_sym)
# convert the sucker
@doc =  @doc.convert
# open write to new file
File.open(params["file_name"], 'w') {|f| f.write(@doc)}

if params["iron_cache"]
  require "iron_cache"
  # start ironcache client
  @client = IronCache::Client.new(:project_id => params["iron_project_id"], :token => params["iron_token"])
  # name cache possible option for user
  @cache = @client.cache(params["cache_name"])
  @cache.put("test", File.read(params["file_name"]))
  item = @cache.get("test")
end

if params["s3"]
  require 'aws/s3'
  client = AWS::S3::Base.establish_connection!(
    :access_key_id     => params["s3_access_key_id"],
    :secret_access_key => params["s3_secret_access_key"]
)
  bucket AWS::S3::Service.buckets.find {|b| b.name == params["s3_bucket"]}
  AWS::S3::S3Object.store(params["file_name"], File.read(params["file_name"]) ,params["s3_bucket"] )
end