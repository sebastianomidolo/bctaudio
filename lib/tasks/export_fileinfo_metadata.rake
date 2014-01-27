# -*- mode: ruby;-*-

# Utilizzo:
# rake export_fileinfo_metadata | psql clavisbct_development informhop
# rake export_fileinfo_metadata | psql clavisbct_production informhop

load 'extras/utils.rb'


# Esempio http://clavisbct.selfip.net/d_objects/393089

desc 'Esportazione metadati dalla tabella file_infos'


def sanifica_collocazione(filename, filepath)
  # puts "sanifica: #{filename}"
  if (filename =~ /^libroparlato/)==0
    colloc=get_collocation('libroparlato',filename)
    # puts "collocazione libro parlato: '#{colloc}'"
    return colloc
  end
  if (filename =~ /^mp3clips/)==0
    # puts filepath
    colloc=get_collocation('cdmusicale',filepath)
    if colloc.blank?
      # puts "colloc blank: #{fname}"
      return nil
    else
      return colloc
    end
  end
  return nil
end

task :export_fileinfo_metadata => :environment do
  sql=%Q{select * FROM file_infos where mp3_tags notnull and collocazione ~* '^BCT'}
  # sql=%Q{select * FROM file_infos where id=8885}
  # puts sql
  flog='/tmp/export_fileinfo_metadata.log'
  fd=File.open(flog,'w')
  ttable='public.import_bctaudio_metatags'
  puts "-- output di export_fileinfo_metadata.rake / logfile: #{flog}"
  puts "DROP TABLE #{ttable};"
  puts "CREATE TABLE #{ttable} (collocation varchar(128), folder varchar(512), filename varchar(2048), tracknum integer, tags xml);"
  puts "COPY #{ttable} (filename,collocation,folder,tracknum,tags) FROM stdin;"
  FileInfo.find_by_sql(sql).each do |fi|
    doc = REXML::Document.new(fi.mp3_tags)
    fname="mp3clips/#{fi.clip_basename}"
    filepath=File.join(fi.container,fi.filepath)
    folder=File.dirname(fi.filepath)
    folder = "\\N" if folder.blank?
    colloc=sanifica_collocazione(fname, filepath)
    if colloc.nil?
      fd.write("Dato mancante di collocazione (file_infos id #{fi.id}): #{fi.collocazione}\n")
      next
    end
    if colloc!=fi.collocazione
      fd.write("controllare collocazione per #{fi.id} : #{colloc} != #{fi.collocazione}\n")
      fd.write("filepath: #{filepath}\n")
    end
    if (colloc =~ /^BCT\./)==0
      colloc.sub!(/^BCT\./, '')
    else
      fd.write("anomalia collocazione per #{fi.id}\n")
    end
    doc.root.attributes['collocation']=colloc
    doc.root.attributes['filepath']=filepath
    # sq=%Q{UPDATE public.d_objects SET tags=#{FileInfo.connection.quote(doc.to_s)} WHERE filename='#{fname}';\n}
    fi.tracknum=-1 if fi.tracknum.blank?
    puts "#{fname}\t#{colloc}\t#{folder}\t#{fi.tracknum}\t#{doc.to_s}"
  end
  puts "\\.\n"
  puts "CREATE INDEX #{ttable.sub('public.','')}_filename_idx ON #{ttable} (filename);"
  fd.close

end


