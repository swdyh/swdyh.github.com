html = File.read('index.html')
s = '<p>by @swdyh</p>'
s2 = '<div style="color: white;margin-top: 30px;text-align: center;">Rails Developer Meetup #7 2017-11-16</div>'
r = html.sub(s, s + s2)
open('index.html', 'w') { |f| f.write(r) }
