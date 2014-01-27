# -*- mode: ruby;-*-
# lastmod  7 novembre 2012
# lastmod  6 novembre 2012
# lastmod  2 novembre 2012
# lastmod 29 ottobre 2012

# convmv -r -f ISO-8859-1 -t UTF-8 libroparlato --notest

desc 'Scansione files per libro parlato [NON USARE]'

task :hd_scan_libroparlato => :environment do

  puts "Non usare, usa invece find_d_objects in clavisbct"
  exit

  # Questo andrebbe reso parametrizzabile in modo da utilizzare diversi
  # modelli di collocazione
  eval(File.read('lib/analisi_collocazione_per_libroparlato.rb'))

  # topdir e' il mount point dell'hd esterno oppure la directory top level
  # che contiene tutte le altre dir. Files presenti in topdir vengono
  # ignorati
  topdir='/home/storage/preesistente'

  # folders e' un array di directories da analizzare; tutte le dirs contenute in
  # questo array condividono la medesima topdir
  folders = ['libroparlato']
  # folders=['CD Biblioteca Musicale/MP3']

  def process_file(collocazione,fname,drive,filepath,container,mp3_tracknum)
    dbg "process_file: #{collocazione} mp3_tracknum: #{mp3_tracknum} -> '#{filepath}'"
    dbg "file '#{fname}' in container: #{container}"

    mdb=MdbItem.find_or_create_by_collocazione(collocazione)
    mdb.title=File.basename(container)
    mdb.save if mdb.changed?

    ext=File.extname(filepath).downcase
    tracknum=mp3_tags="\\N"
    case ext
    when '.mp3'
      tags={}
      mp3_tracknum+=1
      tracknum=mp3_tracknum
      tags['tracknum'] = tracknum
      tags['album'] = File.basename(container)
      tags['title'] = fname
      mp3_tags=tags.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    end
    puts "#{collocazione}\t#{drive}\t#{container}\t#{fname}\t#{tracknum}\t#{mp3_tags}"
    return mp3_tracknum
  end

  def dbg(msg)
    # STDERR.write("#{msg}\n")
  end

  def scan_folder(topdir,folder)
    dbg "analisi folder #{folder}"
    basedir=File.join(topdir,folder)
    dbg "basedir: #{basedir}"
    # Importante: a livello di basedir eventuali files vengono ignorati: solo le
    # directories vengono prese in considerazione, saltando '.' e '..'
    dirs=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}
    dirs.each do |dir|
      scan_dir(topdir,folder,dir)
    end
  end

  def scan_dir(topdir,folder,dir)
    dbg "\nanalizzo dir <#{dir}> presente nel folder <#{folder}> della topdir <#{topdir}>"
    basedir=File.join(topdir,folder,dir)
    subdirs=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}
    subdirs.each do |subdir|
      x=collocazione?(subdir)
      if !x
        dbg "In questa subdir non trovo la collocazione: #{subdir}"
        next
      end
      collocazione=to_collocazione(subdir)
      @mp3_tracknum=0
      scan_album(collocazione,topdir,File.join(folder,dir,subdir),@mp3_tracknum)
    end
  end

  def scan_album(collocazione,topdir,subdir,mp3_tracknum)
    dbg "collocazione #{collocazione} - topdir #{topdir}"
    dbg "subdir #{subdir}"
    basedir=File.join(topdir,subdir)
    entries=Dir.entries(basedir).delete_if {|z| ['.','..'].include?(z)}.sort
    dbg entries.inspect
    entries.each do |entry|
      file_or_dir=File.join(basedir,entry)
      if File.directory?(file_or_dir)
        dbg "questa e' una directory: #{file_or_dir}"
        @mp3_tracknum = 0
        @mp3_tracknum = scan_album(collocazione,topdir,File.join(subdir,entry),@mp3_tracknum)
        dbg "Ora qui: @mp3_tracknum #{@mp3_tracknum}"
      else
        dbg "entry: #{entry} - subdir='#{subdir}'"
        @mp3_tracknum=process_file(collocazione,entry,topdir,file_or_dir,subdir,@mp3_tracknum)
      end
    end
    @mp3_tracknum
  end


  def put_head(drivepath)
    puts "SET CLIENT_ENCODING TO utf8;"
    puts "DELETE FROM file_infos WHERE drive = '#{drivepath}';"
    puts "SELECT setval('file_infos_id_seq', max(id)) from file_infos;"
    puts "COPY public.file_infos (collocazione,drive,container,filepath,tracknum,mp3_tags) FROM stdin;"
  end
  def put_tail
    puts "\\.\n"
  end

  put_head(topdir)
  # @mp3_tracknum=0
  # scan_album('LP.CD MP 37', '/usr/local/data', 'audiolibri/CD MP/MP 037 - GOLDONI - Commedie - REG_Radio',@mp3_tracknum)
  folders.each do |folder|
    scan_folder(topdir,folder)
  end
  put_tail

end

