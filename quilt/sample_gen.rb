require 'quilt'

num = 5
num.times do |i|
  ic = Quilt::Identicon.new rand(1000), :scale => 10
  out = File.join('sample', "quilt-%02d.png" % i)
  ic.write(out)
  p out
end
