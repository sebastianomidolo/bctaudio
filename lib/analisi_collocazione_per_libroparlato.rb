# lastmod 2 novembre 2012

def regexp_collocazione
  /(NA|NB|NT|MP) +((\d+)[ -]|(\d+$))/
end
def collocazione?(str)
  # Questa non pretende che la stringa inizi con la collocazione; potrebbe essere anche
  # a meta' della stringa
  x = regexp_collocazione =~ str
  x.nil? ? false : true
end

def to_collocazione(str)
  regexp_collocazione =~ str
  if $1=='MP'
    p="CD MP"
  else
    p=$1
  end
  num=$2.to_i
  "LP.#{p} #{num}"
end

