# -*- coding: utf-8 -*-
# lastmod 23 novembre 2012  - nuovo: outdir_name
# lastmod 22 novembre 2012  - nuovo: def sizeinfo
# lastmod 16 novembre 2012  - def pack_otherfiles ; corretto bug in #directories
# lastmod  7 novembre 2012
# lastmod 28 settembre 2012
# lastmod 27 settembre 2012
# lastmod 26 settembre 2012 - def directories, top_directory, directories_with_audiofiles
#                             pack_audio_files riscritta e rinominata in pack_audiofiles
# lastmod 24 settembre 2012 - def graphics
# lastmod 20 agosto 2012
# lastmod 13 agosto 2012

require 'ftools'
require 'abbrev'

class MdbItem < ActiveRecord::Base
  attr_accessible :collocazione, :title

  has_many(:files, :class_name=>'FileInfo', :foreign_key=>'collocazione',
           :primary_key=>'collocazione', :order=>'filepath,tracknum')

  def item_details
    return {} if self.source.nil?
    sql="SELECT * FROM #{self.source} WHERE #{self.source_pk}=#{self.record_id}"
    self.connection.execute(sql).first
  end

  def info_files
    c=self.connection.quote(self.collocazione)
    self.connection.execute("SELECT * FROM file_infos WHERE collocazione=#{c} ORDER BY lower(filepath)").collect
  end

  def source_pk
    self.connection.execute("SELECT pg_attribute.attname FROM pg_index, pg_class, pg_attribute WHERE pg_class.oid = '#{self.source}'::regclass AND indrelid = pg_class.oid AND pg_attribute.attrelid = pg_class.oid AND pg_attribute.attnum = any(pg_index.indkey) AND indisprimary").collect.first['attname']
  end

  def other_items
    MdbItem.find_by_sql("SELECT * FROM mdb_items WHERE collocazione=#{self.connection.quote(collocazione)} AND id!=#{self.id} ORDER BY source");
  end

  def graphics
    coll=MdbItem.connection.quote(self.collocazione)
    res=FileInfo.find(:all,
                      :conditions=>"collocazione=#{coll} and tracknum isnull").collect do |x|
      x if ['.jpeg','pdf','.pdf'].include?(File.extname(x.filepath))
    end
    res.compact
  end

  # Restituisce la lista di tutte le directories
  def directories(with_audio_files=false)
    dirlist=[]
    self.files.each do |f|
      if with_audio_files
        next if f.tracknum.nil?
      end
      dir=File.dirname(f.filepath)
      next if dir=='.'
      dirlist << File.dirname(f.filepath)
    end
    return dirlist.sort.uniq
    res=[]
    dirlist.each do |f|
      # res << f
      res << File.basename(f)
    end
    res.uniq.sort
  end

  # Restituisce la lista delle directories che contengono files audio
  def directories_with_audiofiles
    self.directories(true)
  end

  def top_directory
    return nil if self.files.size==0
    f=self.files.first
    File.join(f.drive, f.container)
  end

  def audio_tar_file
    self.pack_otherfiles
    sourcedir=self.pack_audiofiles
    tdir=File.basename(sourcedir)
    dirname=File.dirname(sourcedir)
    tf=Tempfile.new('tartmp')
    tarfile=tf.path
    cmd=%Q{tar --directory "#{dirname}" -cvf "#{tarfile}" "#{tdir}"}
    puts cmd
    Kernel.system(cmd)
    return tf
  end


  def outdir_name
    "#{self.collocazione} - #{self.title}"[0..128]
  end

  def pack_audiofiles
    basedir='/home/seb/mp3cache'
    outdir=File.join(basedir,self.outdir_name)
    # puts "scrivo in: #{outdir}"
    Dir.mkdir(outdir) if !File.exists?(outdir)
    # puts self.id
    topdir=self.top_directory
    return nil if topdir.nil?
    self.directories_with_audiofiles.each do |dir|
      rgxp = Regexp.new("^#{dir}")
      # puts "nel loop: #{dir}"
      destdir=File.join(outdir,dir)
      Dir.mkdir(destdir) if !File.exists?(destdir)
      # sourcedir=File.join(topdir, dir)
      # puts "source dir: #{sourcedir}"
      # puts "source dir: #{dir}"
      # puts "dest dir: #{destdir}"
      self.files.each do |f|
        next if f.trackname.nil?
        next if (f.filepath =~ rgxp).nil?
        puts "dir: #{dir}"
        puts "filepath: #{f.filepath}"
        target_trackname=File.join(destdir,f.trackname)
        # puts f.filetype
        if f.filetype=='MP3'
          target_trackname=File.join(destdir,f.trackname)
          # puts "target_trackname: #{target_trackname}"
          if !File.exists?(target_trackname)
            # puts target_trackname
            File.copy(f.fname,target_trackname)
          end
          f.write_mp3tags(self,target_trackname,dir)
          next
        end
        if f.filetype=='FLAC'
          puts "file flac qui: #{f.id} fname='#{f.fname}' \ndestdir=>#{destdir}"
          ff=FlacFile.new(f.fname)
          if ff.cue_filename.nil?
            # puts "file flac senza cue file: #{f.tracknum} => #{target_trackname}"
            cmd=%Q{/usr/bin/sox "#{f.fname}" "#{target_trackname}"}
            # puts cmd
            Kernel.system(cmd) if !File.exists?(target_trackname)
            f.write_mp3tags(self,target_trackname,dir)
          else
            puts "file flac con cue file #{f.trackname}"
            f.split_tracks(ff, destdir, self, dir)
            break
          end
        end
      end
    end
    outdir
  end

  # Simile alla pack_audiofiles, ma per gli altri files (jpg, pdf etc.)
  # Nota bene: questa procedura e' stata scritta dopo la pack_audiofiles
  # (16 novembre 2012); la sua logica nel creare le directories di
  # destinazione e' migliore: pertanto converra' poi adattare a tale logica
  # anche la pack_audiofiles.
  def pack_otherfiles
    basedir='/home/seb/mp3cache'
    outdir=File.join(basedir,self.outdir_name)
    # puts "scrivo in: #{outdir}"
    Dir.mkdir(outdir) if !File.exists?(outdir)
    topdir=self.top_directory
    return nil if topdir.nil?

    # Creazione delle dir necessarie a contenere i files:
    self.directories.each do |dir|
      puts "nel loop: #{dir}"
      destdir=File.join(outdir,dir)
      puts "creazione dir #{destdir}"
      Dir.mkdir(destdir) if !File.exists?(destdir)
    end
    puts outdir
    okfiles=['image/jpeg','text/plain']
    self.files.each do |f|
      next if !okfiles.include?(f.mime_type)
      target_filename=File.join(outdir,f.filepath)
      puts "#{f.mime_type}: #{target_filename}"
      if !File.exists?(target_filename)
        puts "file copy: #{f.fname}"
        File.copy(f.fname,target_filename)
      end
    end
    outdir
  end

  def sizeinfo
    data={}
    self.files.each do |f|
      next if f.mime_type.nil?
      if f.mime_type=='audio/flac'
        ff=FlacFile.new(f.fname)
        if ff.valid_cue_file?
          puts "flac mono-file - tracknum=#{f.tracknum} size #{f.bfilesize}"
        else
          puts "flac multi-file - tracknum=#{f.tracknum} size #{f.bfilesize}"
          realsize=File.size(f.fname)
          if f.bfilesize!=realsize
            puts "dimensioni file su disco: #{realsize}"
            f.bfilesize=realsize
            f.save
          end
        end
      end
      data[f.mime_type] = 0 if data[f.mime_type].nil?
      data[f.mime_type] += f.bfilesize
    end
    data
  end

  def MdbItem.libroparlato
    sql=%Q{SELECT m.*,c.manifestation_id FROM mdb_items m
            LEFT JOIN clavis_collocs c USING(collocazione)
             WHERE m.collocazione ~* '^LP'
         ORDER BY espandi_collocazione(collocazione);}
    puts sql
    @mdb_items=MdbItem.find_by_sql(sql)
  end

  def MdbItem.trova_o_crea(collocazione)
    return nil if collocazione.blank?
    MdbItem.find_or_create_by_collocazione(collocazione)
  end

end
