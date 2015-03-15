NB. purpose built hashmap / dictionary class
NB. for msgpack.
NB. see: http://www.jsoftware.com/jwiki/Essays/DataStructures#Associative_Array
NB. Will extend the dictionary example in the above link.

coclass 'dictionary'
okchar=:~. (,toupper) '0123456789abcdefghijklmnopqrstuz'
ok=: ] [ [: assert [: *./ e.&okchar
intern=: [: ('z' , ok)&.> boxxopen
has=: _1 < nc@intern
set=: 4 :'(intern x)=: y'
get=: ".@>@intern