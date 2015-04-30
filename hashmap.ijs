NB. purpose built hashmap / dictionary class
NB. for msgpack.
NB. reference see: http://www.jsoftware.com/jwiki/Essays/DataStructures#Associative_Array




NB. operators
(XOR=: 22 b.),(OR=: 23 b.),(AND=: 17 b.),(NOT=: 20 b.),
SHIFT=: 33 b.

NB. ============ HASHMAP CLASS ==============

NB. HashMap class contains hashmap implementation.
NB. Hashmap will contain Entry objects.
coclass 'HashMap'
entries=: ''
count=: ''
MAX=: 40

create=: monad define
for_j. i. MAX do.
  entries=: entries, (conew 'Entry')
end.
)

size =: monad define
count =. 0
for_j. i. MAX do.
ent =. j{entries
if. isSet__ent do. count =. count + 1
end.
end.
count
)

NB. set a new key value pair.
NB. Should be boxed pair (key;value)
set=: monad define
rk=. >0{y NB. raw key
hk=. hash rk NB. hashed key
val=. >1{y NB. value
i=. conew 'Entry'
create__i rk;hk;val
hk append i
''
)

enumerate =: monad define
result =. ''
for_j. i. MAX do.
ent =. j{entries
if. isSet__ent do. 
result =. result,<(rawKey__ent; value__ent)
end.
end.
result
)

apply =: monad define
result =. ''
for_j. i. MAX do.
ent =. j{entries
if. isSet__ent do. 
result =. result,((y`:6) rawKey__ent), ((y`:6) value__ent)
end.
end.
result
)

NB. Append the new Entry to the hashmap.
append=: dyad define
ent=. x { entries
if. 0 = isSet__ent do.
  entries=: y x} entries
else.
  ent=. x{ entries
  appendToLast__ent y
end.
)

NB. Get the value for the given key.
get=: monad define
ky=. y
hk=. hash ky
ent=. hk{entries
if. 0 = isSet__ent do. 'ERROR'
elseif. key__ent = hk do.
  matches__ent ky
end.
)

containsValue=: monad define
ky=. y
hk=. hash ky
ent=. hk{entries
if. 0 = isSet__ent do. 0
elseif. key__ent = hk do.
  contains__ent ky
end.
)

NB. Hash the key.
hash=: monad define
h=. a.i.": y
h=. +/h
h1=. 3 (33 b.) h
h2=. 13 (33 b.) h
h=. h XOR h1 XOR h2
h=. h XOR (7 ( 33 b.) h)
MAX | h
)

destroy=: codestroy


NB. =============== ENTRY CLASS =============

NB. Entry class contains key value pair and "pointer"
NB. to potential next entry in LinkedList fashion.
coclass 'Entry'
key=: ''   	NB. The key (hashed)
value=: '' 	NB. The value
next=: ''  	NB. The next value, if any
rawKey=: '' 	NB. The raw, unhashed, key
isSet=: 0 	NB. flag for instantiated or not.

create=: 3 : 0
rawKey=: >0{y
key=: >1{y
value=: >2{y
isSet=: 1
)

contains=: monad define
rk=: y
if. isSet = 0 do. 0
elseif. (<rawKey) = <rk do.
  1
elseif. 1 do.
  contains__next y
end.
)

matches=: 3 : 0
rk=: y
if. isSet = 0 do. 'ERROR'
elseif. (<rawKey) = <rk do.
  value
elseif. 1 do.
  matches__next y
end.
)

appendToLast=: 3 : 0
smoutput ": (# next)
if. 0 = # next do.
  next=: y
else.
  appendToLast__next y
end.
)

destroy=: codestroy






F=: conew 'HashMap'
create__F ''
set__F 'key1';'value1'
list=: ('key'&,@:([: ": ]))"_ 0 ( i.45)
listX=: list;"1 1 ('something',"_ 1 list)
