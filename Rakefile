#
# Rakefile for self publishing ebook of Kindle made by scanning paper book.
#
# modify parameters by your environment:
#   SRC (must): source PDF file name.
#   TOP, BOTTOM, LEFT, RIGHT: default margins (pixel) of trimming.
#   SIZE: adjust image size by destination format.
#
# for Debian or Ubuntu user, needs packages below:
#   poppler-utils poppler-data imagemagick pdftk sam2p
#

require 'pathname'

SRC = ENV['SRC'] || 'sample.pdf'

TOP = ENV['TOP'] || 250
BOTTOM = ENV['BOTTOM'] || 100
LEFT = ENV['LEFT'] || 50
RIGHT = ENV['RIGHT'] || 50
OUT_DIR = ENV['OUT_DIR'] || './'
OUT_EXT = ENV['OUT_EXT'] || 'out'
FUZZ = ENV['FUZZ'] || '50%'

# for Kindle Voyage (display size 1080x1440)
SIZE = '1016x1364' # for small books reading portrait style

# for Kindle Paperwhite (display size 768x1024)
#SIZE = '658x905' # for small books reading portrait style
#SIZE = ### UNKNOWN ### # for large books reading landscape style
#SIZE = ### UNKNOWN ### # for generating mobi, portrait style only
#SIZE = ### NOT SUPPORTED BY PW ### # for generating zip archived png files 

# for Kindle, Kindle Keyboard (display size 600x800)
#SIZE = '560x735' # for small books reading portrait style
#SIZE = '720' # for large books reading landscape style
#SIZE = 'x693' # for generating mobi, portrait style only
#SIZE = '600x800' # for generating zip archived png files 

#---------------------------------------------------------

PPM_DIR = './ppm'; directory PPM_DIR
PNG_DIR = './png'; directory PNG_DIR
PDF_DIR = './pdf'; directory PDF_DIR


DST = (Pathname.new(OUT_DIR) +
       Pathname.new(SRC).basename.to_s.sub( /\.pdf$/, ".#{OUT_EXT}.pdf" )
      ).to_s
MOBI = SRC.sub( /\.pdf$/, '.mobi' )
OPF = SRC.sub( /\.pdf$/, '.opf' )
HTML = SRC.sub( /\.pdf$/, '.html' )
ZIP = SRC.sub( /\.pdf$/, '.zip' )

PHASE3_COMMAND = ENV['PHASE3_COMMAND'] || 'sam2p'

def count_pages
	open( "|pdfinfo '#{SRC}'", 'r:utf-8', &:read ).scan( /^Pages:\s*(\d+)/ ).flatten[0].to_i
end

def book_title
	open( "|pdfinfo '#{SRC}'", 'r:utf-8', &:read ).scan( /^Title:\s*(.+)$/ ).flatten[0]
end

def book_author
	open( "|pdfinfo '#{SRC}'", 'r:utf-8', &:read ).scan( /^Author:\s*(.+)$/ ).flatten[0]
end

def image_list( dir, ext, count )
	[].tap do |l|
		0.upto( count - 1 ) do |i|
			l << "#{dir}/tmp-#{'%03d' % i}.#{ext}"
		end
	end
end

def ppm_exist?( ppm )
	File::exist?( ppm ) || File::exist?( ppm.sub(/ppm$/, 'pbm') )
end

def ppm_file( ppm )
	if File::exist?( ppm )
		ppm
	elsif File::exist?( ppm.sub(/ppm$/, 'pbm') )
		ppm.sub(/ppm$/, 'pbm')
	end
end

def ppm2png( ppm, png )
  sh "mogrify "\
    " -type Grayscale -background white"\
    " -deskew 40%" \
    " -chop #{LEFT}x#{TOP}"\
    " -gravity SouthEast -chop #{RIGHT}x#{BOTTOM}"\
    " -gravity NorthWest -fuzz #{FUZZ} -trim -resize #{SIZE}"\
    " #{/x/ =~ SIZE ? '' : '-gravity SouthWest -splice 1x15 -gravity NorthEast -splice 1x15'}"\
    " #{ENV["KINDLIZER_PHASE2_OPT"]}"\
    " -path \"#{PNG_DIR}\"" \
    " -format png" \
    " #{PPM_DIR}/*.ppm"
end

def png2pdf_mogrify
  sh "mogrify " \
     " #{ENV['KINDLIZER_PHASE3_OPT']}" \
     " -format pdf" \
     " +repage" \
     " -path #{PDF_DIR}" \
     " #{PNG_DIR}/*.png"
end

def png2pdf( png, pdf )
  sh "sam2p -j:quiet #{ENV['KINDLIZER_PHASE3_OPT']} #{png} #{pdf}"
end

pages = count_pages
PPMS = image_list( PPM_DIR, 'ppm', pages )
PNGS = image_list( PNG_DIR, 'png', pages )
PDFS = image_list( PDF_DIR, 'pdf', pages )

PNGS.each_with_index do |png, i|
	file PDFS[i] => [PDF_DIR, PNGS[i]] do |t|
    if PHASE3_COMMAND == 'mogrify'
      unless File.exist?(PDFS[-1]) then
        png2pdf_mogrify
      end
    else
      png2pdf( t.prerequisites[1], t.name )
    end
	end

	file PNGS[i] => [PNG_DIR, PPMS[i]] do |t|
    unless File.exist?(PNGS[-1]) then
      ppm2png( t.prerequisites[1], t.name )
    end
	end

	file PPMS[i] => [PPM_DIR, SRC] do
		unless ppm_exist?( PPMS[-1] ) then
			#sh "pdftoppm -r 300 -gray '#{SRC}' #{PPM_DIR}/tmp"
			sh "pdfimages '#{SRC}' #{PPM_DIR}/tmp"
		end
	end
end

task :default => :pdf

desc 'generate pdf file by concat all png files.'
task :pdf => DST

file DST => [PDF_DIR, 'metadata.txt'] + PDFS do
	sh "pdftk #{PDFS.join ' '} cat output '#{PDF_DIR}/tmp_output.pdf'"
	sh "pdftk '#{PDF_DIR}/tmp_output.pdf' update_info metadata.txt output '#{DST}'" 
end

desc 'generate metadata file from source pdf.'
task :metadata => 'metadata.txt'

file 'metadata.txt' => SRC do |t|
	sh "pdftk #{t.prerequisites.map {|i| "'#{i}'" }.join ' '} dump_data output ./#{t.name}"
end

desc 'crop ppm files to png files.'
task :png => [PNG_DIR] + PNGS

rule '.png' => /\.p[bp]m$/ do |t|
	ppm2png( t.prerequisites[0], t.name )
end

desc 'extract image files from source pdf.'
task :ppm => [PPM_DIR, SRC] + PPMS

desc 'cleanap ppm images.'
task 'clean-ppm' do
  rm_rf PPM_DIR
end

desc 'cleanap png images.'
task 'clean-png' do
  rm_rf PNG_DIR
end

desc 'cleanap temporaly pdf files.'
task 'clean-pdf' do
  rm_rf PDF_DIR
end

desc 'cleanap all tmp files.'
task :clean => ['clean-png', 'clean-ppm', 'clean-pdf'] do
	begin
		rm 'metadata.txt'
	rescue
	end
	begin
		rm [HTML, OPF]
	rescue
	end
end

desc 'generate zip file'
task :zip => PNGS do
  sh "zip -j '#{ZIP}' #{PNGS.join ' '}"
end

desc 'generate MOBI file.'
task :mobi => [OPF, HTML] + PNGS do |t|
	sh "kindlegen '#{OPF}' -o '#{MOBI}'"
end

rule '.opf' => '.pdf' do |t|
	opf = <<-OPF.gsub( /^\t/, '' )
	<?xml version="1.0" encoding="utf-8"?>
	<package unique-identifier="uid">
		<metadata>
			<dc-metadata xmlns:dc="http://purl.org/metadata/dublin_core"
			xmlns:oebpackage="http://openebook.org/namespaces/oeb-package/1.0/">
			  <dc:Title>#{book_title}</dc:Title>
			  <dc:Language>en-US</dc:Language>
			  <dc:Creator>#{book_author}</dc:Creator>
			  <dc:Date>#{Time::now.strftime '%m/%d/%Y'}</dc:Date>
			</dc-metadata>
			<x-metadata>
			  <output encoding="utf-8" content-type="text/x-oeb1-document"></output>
			  <EmbeddedCover>#{PNGS[0]}</EmbeddedCover>
			</x-metadata>
		</metadata>
		<manifest>
			<item id="contents" media-type="text/html" href="#{HTML}"></item>
		</manifest>
		<spine>
			<itemref idref="contents" />
		</spine>
		<tours></tours>
		<guide>
			<reference type="start" title="contents" href="#{HTML}"></reference>
		</guide>
	</package>
	OPF
	open( t.name, 'w:utf-8' ){|f| f.write opf}
end

rule '.html' => '.pdf' do |t|
	html = <<-HTML.gsub( /^\t/, '' )
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
	<html lang="ja-JP">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
		<title>#{book_title}</title>
	</head>
	<body style="text-align: right;">
		#{PNGS.map{|j| %Q|<img style="height: 100%;" src="#{j}" />|}.join "<mbp:pagebreak />\n\t\t"}
	</body>
	</html>
	HTML
	open( t.name, 'w:utf-8' ){|f| f.write html}
end

