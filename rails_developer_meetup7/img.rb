require 'RMagick'

list = Magick::ImageList.new
image = Magick::Image.new(1024, 640) { self.background_color = '#4caf50' }
list << image
list.write("cover.png")
