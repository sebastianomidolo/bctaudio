# lastmod 23 novembre 2012  - def rettifica_collocazione
# lastmod 18 novembre 2012  - modifica a trackname (include stringa parlante con titolo)
# lastmod  6 novembre 2012  - def FileInfo.files_for_libroparlato
# lastmod  4 ottobre 2012   - def filesize
# lastmod 26 settembre 2012 - def trackname ; def write_mp3tags
# lastmod 24 settembre 2012 - def re_read_mp3tags_from_file / re_read_mp3tags_from_file!
# lastmod 21 settembre 2012 - def coverimage_link
# lastmod 20 settembre 2012 - def FileInfo.files_for_manifestation
#                             def get_mp3tag
# lastmod  4 settembre 2012 - split_tracks
# lastmod 29 agosto 2012 - Modificato to_clip che tratta ora anche i flac con "index"
# lastmod 20 agosto 2012 - def to_clip

require 'mp3info'
require 'taglib'
require "rexml/document"

REGEX_BCT = /((((\d+|AMA|AUD|CLA)\.(F|P|FF|MC|A))|((CD\.\d+)))(\.[^ ]*)) ?/

REGEX_LP  = /(NA|NB|NT|MP) +((\d+)[ -]|(\d+$))/

class FileInfo < ActiveRecord::Base
  # attr_accessible :title, :body

  # 
  # Riconosce solo alcune tipologie, basandosi sull'estensione (debole metodo, ma qui va bene)
  def filetype
    t={
      '.flac' => 'FLAC',
      '.mp3'  => 'MP3'
    }
    t[File.extname(filepath).downcase]
  end

  def filesize
    # puts self.fname
    File.size(self.fname)
  end

  def trackname(ext='.mp3')
    return nil if self.tracknum.nil?
    title=self.get_mp3tag('title')
    title=File.basename(self.filepath, File.extname(self.filepath)) if title.blank?
    t=format "%03d - #{title}%s", self.tracknum, ext
    t.gsub("/", "-")
  end
  def fname
    File.join(self.drive, self.container, self.filepath)
  end
  def clip_basename(ext="mp3")
    "clip_#{id}.#{ext}"
  end
  def to_clip(ext="mp3")
    doc = REXML::Document.new(self.mp3_tags)
    index=doc.elements.first.elements['index01']
    # icv = Iconv.new('LATIN1', 'UTF-8')
    # fn=icv.iconv(self.fname)
    fn=self.fname
    if index.nil?
      cmd=%Q{/usr/bin/sox "#{fn}" "#{clip_filename(ext)}" trim 0 30 fade h 0 0:0:30 4}
    else
      start=index.text[0..4]
      puts "index start: #{start}"
      cmd=%Q{/usr/bin/sox "#{fn}" "#{clip_filename(ext)}" trim #{start} 30 fade h 0 0:0:30 4}
    end
    puts cmd
    Kernel.system(cmd)
  end

  def clip_path
    "/home/seb/mp3cache/mp3clips"
  end

  def clip_filename(ext="mp3")
    File.join(self.clip_path,self.clip_basename(ext))
  end

  def get_clip(ext="mp3")
    self.to_clip(ext) if !File.exists?(self.clip_filename)
    File.read(self.clip_filename(ext))
  end

  def write_mp3tags(mdb_item,targetfile,disk)
    # puts "writing mp3tags for #{self.id} to #{targetfile} (disk=#{disk})"
    flds=["note", "phonogram", "numero_editoriale", "editore", "numero_volumi"]

    idt=mdb_item.item_details
    commento=[]
    flds.each do |f|
      next if idt[f].blank?
      commento << "#{f}: #{idt[f]}"
    end

    Mp3Info.open(targetfile) do |mp3|
      mp3.tag.title = mp3.tag2.TIT2 = self.get_mp3tag('title')
      mp3.tag.tracknum=self.tracknum.to_i
      mp3.tag.artist=mdb_item.item_details['autore']
      mp3.tag.album=mdb_item.item_details['titolo'] + " (#{disk})" if !mdb_item.item_details['titolo'].blank?
      mp3.tag2.options[:lang] = "ITA"
      commento = "collocazione #{self.collocazione} non trovata su archivio mdb" if commento.size==0
      # commento="debug on - #{Time.now}"
      mp3.tag2.COMM = commento
    end
  end

  # http://ruby-mp3info.rubyforge.org/
  # ff deve essere un'istanza di FlacFile
  # mdb_item istanza di MdbItem oppure nil
  def split_tracks(ff, outdir, mdb_item, subdir)
    sox_info=ff.sox_split_info
    return nil if sox_info.nil?
    # puts "soxinfo size #{sox_info.size}"
    # puts "outdir: #{outdir}"

    cnt=0
    m=nil
    sox_info.each do |si|
      # puts si.inspect
      tracknum,start,len=si
      outfile=File.join(outdir, format("%03d%s", tracknum, '.mp3'))
      cmd=%Q{/usr/bin/sox "#{self.fname}" "#{outfile}" trim #{start} #{len}}
      # puts cmd

      Kernel.system(cmd) if !File.exists?(outfile)

      track_title=ff.cue_tracklist[cnt]['title']
      # track_title=icv.iconv(ff.cue_tracklist[cnt]['title'])
      # "La Mer: I. De l'aube à midi sur la mer"
      # track_title=icv.iconv(track_title)
      # track_title=ff.get_mp3tag('title')
      # track_title="La Mer: I. De l'aube à midi sur la mer"
      puts "track_title: '#{track_title}'"
      
      if tracknum!=self.tracknum
        sql="select f2.* from file_infos f1 join file_infos f2 on(f1.id=#{self.id} and f1.id!=f2.id AND f1.filepath=f2.filepath AND f2.tracknum=#{tracknum})"
        finfo=FileInfo.find_by_sql(sql).first
      else
        finfo=self
      end
      if finfo.nil?
        puts "non trovato FileInfo:\n#{sql}"
      else
        finfo.write_mp3tags(mdb_item,outfile,subdir)
      end

=begin
      TagLib::FileRef.open(outfile) do |file|
        prop = file.audio_properties
        puts prop.length
        puts prop.bitrate
      end 
      TagLib::FileRef.open(outfile) do |file|
        tag = file.tag
        puts tag.artist
        puts tag.title
      end
      Mp3Info.open(outfile) do |mp3|
        mp3.tag.title = mp3.tag2.TIT2 = track_title
        mp3.tag.tracknum=tracknum.to_i
        #mp3.tag.artist = "artist name"
      end
=end

      cnt+=1
    end
  end

  def get_mp3tag(tag)
    doc = REXML::Document.new(self.mp3_tags)
    elem=doc.elements.first.elements[tag]
    elem.nil? ? nil : elem.text
  end

  def re_read_mp3tags_from_file
    # mp3filename="/mnt/nfs/biblio/CD Biblioteca Musicale/MP3/L - 99/99.F.203 - Mozart/Così Fan Tutte 1/03 - N.2 Terzetto- 'È la fede delle femmine' -- Recitativo- .mp3"
    puts self.filepath
    return nil if File.extname(self.filepath)!='.mp3'
    puts "ok"
    # icv = Iconv.new('LATIN1','UTF-8')
    # mp3filename=icv.iconv(self.fname)
    mp3filename=self.fname
    m=Mp3Info.open(mp3filename)
    self.mp3_tags=m.tag.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    self
  end
  def re_read_mp3tags_from_file!
    r=re_read_mp3tags_from_file
    r.save if !r.nil?
  end

  def coverimage_link
    coll=FileInfo.connection.quote(self.collocazione)
    ff=FileInfo.find(:all, :conditions=>"collocazione=#{coll} and tracknum isnull and filepath ~* '.jpg'")
    fm=FileMagic.new
    id=nil
    ff.each do |fi|
      puts fi.fname
      type=fm.file(fi.fname)
      id=fi.id
      break if (/^JPEG image/ =~ type)==0
    end
    id
  end

  def content_type
    require 'filemagic'
    fm=FileMagic.mime
    fm.file(self.fname)
    #"image/jpeg; charset=binary"
    #"image/jpeg"
  end

  def rettifica_collocazione
    c=collocazione_da_nomefile
    if c!=self.collocazione
      self.collocazione=c
      self.save if self.changed?
    end
    # Rettifico ora anche le collocazioni dei files collegati a questo
    # (via container)
    puts "qui"
    FileInfo.find_all_by_container(self.container).each do |f|
      next if f.id==self.id
      f.collocazione=c
      f.save if f.changed?
      puts f.collocazione
    end
  end

  def collocazione_da_nomefile
    if /^LP/ =~ self.collocazione
      return "Non funziona per collocazioni LP (libro parlato)"
    end
    if /^BCT./ =~ self.collocazione
      # puts "self.collocazione: #{self.collocazione}"
      return FileInfo.collocazione_da_nomefile('BCT', self.container, REGEX_BCT)
    end
    nil
  end

  def FileInfo.collocazione_da_nomefile(section,filename,regex)
    regex =~ filename
    "#{section}.#{$1}"
  end

  def FileInfo.files_for_manifestation(manifestation_id)
    sql=%Q{SELECT fi.* FROM file_infos fi JOIN clavis_collocs cc USING(collocazione)
  WHERE cc.manifestation_id=#{manifestation_id} AND tracknum notnull
  ORDER BY fi.filepath, fi.tracknum;}
    FileInfo.find_by_sql(sql)
  end

  def FileInfo.files_for_collocazione(collocazione)
    coll=ActiveRecord::Base.connection.quote(collocazione)
    sql=%Q{SELECT * FROM file_infos
  WHERE tracknum notnull AND collocazione=#{coll}
  ORDER BY container, filepath, tracknum;}
    FileInfo.find_by_sql(sql)
  end

end
