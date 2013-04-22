-- lastmod 23 agosto 2012

BEGIN; DROP VIEW public.mp3_albums; COMMIT;
CREATE VIEW public.mp3_albums AS
 SELECT DISTINCT collocazione,
  (xpath('//album/text()',mp3_tags))[1]::text AS mp3_album
 FROM file_infos
 WHERE (xpath('//album/text()',mp3_tags))[1]::text NOTNULL;


BEGIN; DROP VIEW public.mp3_titles; COMMIT;
CREATE VIEW public.mp3_titles AS
 SELECT id,
  (xpath('//title/text()',mp3_tags))[1]::text AS mp3_title
 FROM file_infos
 WHERE (xpath('//title/text()',mp3_tags))[1]::text NOTNULL;


BEGIN; DROP VIEW public.mp3_artists; COMMIT;
CREATE VIEW public.mp3_artists AS
 SELECT DISTINCT collocazione,
  (xpath('//artist/text()',mp3_tags))[1]::text AS mp3_artist
 FROM file_infos
 WHERE (xpath('//artist/text()',mp3_tags))[1]::text NOTNULL;

