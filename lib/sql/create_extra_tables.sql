begin;drop table track_titles;commit;

create table track_titles as (select id,collocazione,
 (xpath('//title/text()',mp3_tags))[1]::text as track_title
  from file_infos where (xpath('//title/text()',mp3_tags))[1]::text!='');
create INDEX track_titles_collocazione_idx on track_titles (collocazione);
