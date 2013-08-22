require 'quilt'
require 'fileutils'

dir = 'sample_'
FileUtils.mkdir_p dir

num = 5
num.times do |i|
  r = rand(1000000)
  ic = Quilt::Identicon.new r, :scale => 10
  out = File.join(dir, "quilt-%02d.png" % (i + 1))
  ic.write(out)
  p [out, r]
end
