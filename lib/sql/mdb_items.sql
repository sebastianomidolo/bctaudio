-- lastmod 10 agosto 2012

TRUNCATE public.mdb_items;
-- SELECT setval('mdb_items_id_seq', (SELECT MAX(id) FROM mdb_items)+1);
SELECT setval('mdb_items_id_seq', 1);

INSERT INTO public.mdb_items (record_id,collocazione,title,source)
 (SELECT idvolume,collocazione,titolo,'audiovisivi.t_volumi'
 FROM audiovisivi.t_volumi where collocazione notnull);

INSERT INTO public.mdb_items (record_id,collocazione,title,source)
 (SELECT record_id,col_bib,titolo,'archivio_mp3.archivio_dischi'
  FROM archivio_mp3.archivio_dischi where col_bib notnull);

INSERT INTO public.mdb_items (record_id,collocazione,title,source)
 (SELECT id_disco,coll_biblioteca_mus,titolo,'fonoteca.fonoteca'
  FROM fonoteca.fonoteca where coll_biblioteca_mus notnull);

UPDATE mdb_items SET collocazione = 'BCT.' || sanifica_collocazione(collocazione);
