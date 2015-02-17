require 'streamio-ffmpeg'


require "benchmark"
require 'open-uri'

p Benchmark.measure  {
	movie = FFMPEG::Movie.new("harddrivespinning.mp4")
	p "movie.duration  : #{movie.duration } "
	p "movie.bitrate : #{movie.bitrate} "
	p "movie.size : #{movie.size} "
	p "movie.video_stream : #{movie.video_stream} "
	p "movie.video_codec : #{movie.video_codec} "
	p "movie.colorspace : #{movie.colorspace} "
	p "movie.resolution : #{movie.resolution} "
	p "movie.width : #{movie.width} "
	p "movie.height : #{movie.height} "
	p "movie.frame_rate : #{movie.frame_rate} "
	p "movie.audio_stream : #{movie.audio_stream} "
	p "movie.audio_codec : #{movie.audio_codec} "
	p "movie.audio_sample_rate : #{movie.audio_sample_rate} "
	p "movie.audio_channels : #{movie.audio_channels} "
	p "movie.valid? : #{movie.valid?} "
}