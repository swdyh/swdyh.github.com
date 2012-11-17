# -*- coding: utf-8 -*-
require 'nokogiri'
require 'redcarpet/compat'

unless ARGV.first
  eixt
end

path = ARGV.first
html = Markdown.new(IO.read path).to_html
doc = Nokogiri::HTML html
list = doc.css('h1').map do |i|
  nodes = []
  s = i.next_sibling
  while s do
    if s.name == 'h1'
      break
    else
      nodes.push s
      s = s.next_sibling
    end
  end
  [i, nodes]
end

builder = Nokogiri::HTML::Builder.new do |doc|
  doc.html {
    doc.body {
      list.each_with_index do |i, index|
        doc.div(:class => 'slide', :id => "p%02d" % (index + 1)) {
          doc.div {
            doc.section {
              doc.header {
                doc.h2 { doc.text i[0].text }
              }
            }
          }
        }
      end
    }
  }
end

html_ = builder.to_html
doc_ = Nokogiri::HTML.parse(html_)
doc_.css('header').each_with_index do |i, index|
  list[index][1].each do |j|
    if j.name == 'pre'
      lines = j.child.text.split("\n")
      j.child.remove
      lines.each do |c|
        code = Nokogiri::XML::Node.new 'code', doc_
        code.content = c
        j << code
      end
    end
    i.parent << j
  end
end

body = doc_.root.child.children.map {|i| i.to_s }.join('')

title = doc_.at_css('h2').text
subtitle = doc_.at_css('p').text
header = <<-EOS
<!DOCTYPE HTML>
<html lang="ja-JP">
<head>
	<title>#{title}</title>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=1274, user-scalable=no">
	<link rel="stylesheet" href="themes/ribbon/styles/style.css">
	<link rel="stylesheet" href="themes/ribbon/styles/print.css" media="print">
	<!--
		To apply styles to the certain slides
		use slide ID to get needed elements
		-->
	<style>
		h2 {
			color:#0d0;
		}
		#p01 h2, #p01 p {
			text-align:center;
		}
		#p01 h2 {
			font-size:70px;
		}
		#p01 p {
			font-size:30px;
		}
		.slide ul {
			margin: 0;
		}
		.slide header{
			margin-bottom: 20px;
		}
	</style>
</head>
<body class="list">
	<header class="caption">
		<h1>#{title}</h1>
		<p>#{subtitle}</p>
	</header>
EOS

footer = <<-EOS
	<div class="progress"><div></div></div>
	<script src="scripts/script.js"></script>
	<!-- slide template https://github.com/pepelsbey/shower -->
</body>
</html>
EOS

out = File.basename(path, '.md') + '.html'
open(out, 'w') { |f| f.write [header, body, footer].join('') }
puts out
