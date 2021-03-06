NB. J implementation of MsgPack
NB.


require '~user/projects/msgpack-j/hashmap.ijs'
require '~user/projects/msgpack-j/utils.ijs'


NB. BYTE PREFIXES - constants
(nil=: 'c0'),(reserved=: 'c1'),(false=: 'c2'),(true=: 'c3'),(bin8=: 'c4'),(bin16=: 'c5'),(bin32=: 'c6'),(ext8=: 'c7'),(ext16=: 'c8')
(ext32=: 'c9'),(float32=: 'ca'),(float64=: 'cb'),(uint8=: 'cc'),(uint16=: 'cd'),(uint32=: 'ce'),(uint64=: 'cf'),(int8=: 'd0'),(int16=: 'd1')
(int32=: 'd2'),(int64=: 'd3'),(fixext1=: 'd4'),(fixext2=: 'd5'),(fixext4=: 'd6'),(fixext8=: 'd7'),(fixext16=: 'd8'),(str8=: 'd9'),(str16=: 'da')
(str32=: 'db'),(array16=: 'dc'),(array32=: 'dd'),(map16=: 'de'),(map32=: 'df')

is_boxed=: 0&<@:L.

NB. Same as hfd, but prepends a leading
NB. '0' onto hex strings with odd number of
NB. characters.
hfd2=: hfd`(('f'&,@hfd)`('0'&,@hfd)@.(0&<))@.(2&|@#@hfd)

NB. Calculates hex from decimal
NB. and stretches the number of bytes to the
NB. required amount, either padding 0's or F's
hfd_stretch=: dyad define
targetlen=. x
h=. hfd2 y
result=. h
diff=. targetlen - (-: # h)
if. diff > 0 do.
  if. y < 0 do. append=. (2*diff) $ 'f'
  else. append=. (2*diff) $ '0' end.
  result=. append, result
end.
result
)
NB. Get the decimal representation of the hex string
dfh_unstretch=: dfh@] - 2&^@(8&*@[)

NB. =========================================================
NB. PACK AN OBJECT
NB. =========================================================
pack_obj=: monad define
result=. ''
dt =. get_type y
if. dt -: 'HashMap' do.
packMap y
else.
boxy=. datatype y
len=. # y
shape=. $ y
if. is_boxed y do. result=. pack_box y
elseif. boxy -: 'literal' do. result=. pack_string y
elseif. (# shape) > 1 do.
  prefix=. hfd2 144 OR {. shape
  ord=. 0&>.<:#shape
  result=. ' '-.~,"_ prefix, (pack_obj"ord ) y 
elseif. len > 1 do. result=. ' '-.~,"_ pack_array y
elseif. (<boxy) e. ( 'integer' ; 'boolean') do. result=. pack_integer y
elseif. boxy -: 'floating' do. result=. pack_float y
end.
result
end.
)



NB. =========================================================
NB. PACK INTEGERS
NB. =========================================================
convert_int=: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:4))
pack_integer=: monad define

if. y < 0 do.
  if. y > _32 do. NB. 5 bits 111YYYYY form
    1 hfd_stretch"0 0 y
  elseif. y > _128 do.
    int8, (1 hfd_stretch y)
  elseif. y > (_1*2^16) do.
    int16, (2 hfd_stretch y)
  elseif. y > (_1*2^32) do.
    int32, (4 hfd_stretch y)
  elseif. y > (_1*2^64) do.
    int64, (8 hfd_stretch y)
  elseif. 1 do.
NB. NOTHING
    1
  end.
elseif. 1 do.
  if. y=0 do. '00'
  elseif. y < 128 do.
    hfd2"0 y
  elseif. y < 256 do.
    uint8, (1 hfd_stretch y)
  elseif. y < (2^16) do.
    uint16, (2 hfd_stretch y)
  elseif. y < (2^32) do.
    uint32, (4 hfd_stretch y)
  elseif. y < (2^64) do.
    uint64, (8 hfd_stretch y)
  elseif. 1 do.
    1
  end.
end.
)


NB. =========================================================
NB. PACK FLOATS
NB. =========================================================
convert_float=: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:5))
pack_float=: monad define
if. (=<.) y do. pack_integer y NB. if can be cast to integer then pack as an integer.
elseif. 1 do. float64, convert_float y
end.
)

NB. =========================================================
NB. PACK STRINGS
NB. =========================================================
convert_string=: , @: hfd @: (a.&i.)
NB. pack strings to msgpack
pack_string=: monad define
hexstr=. convert_string y
len=. 2%~ # hexstr
if. len < 32 do. # NB. Up to 32 bytes
  pre=. hfd2 160 OR len
  pre, hexstr
elseif. len < 2^8 do.
  str8 , (2 hfd_stretch len), hexstr
elseif. len < 2^16 do.
  str16 , (4 hfd_stretch len), hexstr
elseif. len < 2^32 do.
  str32 , (8 hfd_stretch len), hexstr
elseif. 1 do.
  1
end.
)


NB. =========================================================
NB. PACK ARRAYS
NB. =========================================================
pack_array=: monad define
hexArr=. ' '-.~ pack_obj"0 y NB. pack the items
len=. # hexArr
if.len < 16 do.
  pre=. hfd2 144 OR len NB. 1001XXXX
  ' '-.~ , pre, (hexArr)
elseif. len < 2^16 do.
  array16 , (2 hfd_stretch len), (,hexArr)
end.
)


NB. =========================================================
NB. PACK BOX
NB. =========================================================
pack_box=: monad define
len=. # y
if. len = 1 do. pack_obj > y
else.
  if.len < 16 do.
    pre=. hfd2 144 OR len
    ord=. 0&>.<:#$ y
    ' '-.~ , pre, (, pack_box"ord y)
  elseif. len < 2^16 do.
    ord=. 0&>.<:#$ y
    ' '-.~ array16 , (2 hfd_stretch len), (, pack_box"ord y)
  end.
end.
)


NB. =========================================================
NB. PACK BIN
NB. =========================================================
pack_bin=: monad define
len=. # y
if. len < (2^8) do. bin8, (1 hfd_stretch len), y
elseif. len < (2^16) do. bin16, (2 hfd_stretch len), y
elseif. len < (2^32) do. bin32, (4 hfd_stretch len), y
end.
)

NB. =========================================================
NB. PACK NIL
NB. probably pointless
NB. =========================================================
pack_nil=: nil

NB. =========================================================
NB. PACK MAP
NB. packs map objects. (Map reference datatypes MUST be symbols
NB. =========================================================
packMap=: monad define
hMap=. 5 s: y NB. hashmap
str=. ,>hMap
hMap=. <str
size=. size__hMap ''
prefix=. '8', hfd size
NB. packUp will pack the key and the value of kvp pair and append them.
px=. ,@:pack_obj@:>
packUp =. px"0@:>
l=. enumerate__hMap ''
a=. (' '-.~,(packUp"0) l)
prefix , a
)



NB. Pack bytes
pack=: a.&({~)@:dfh@:byte_shape@:pack_obj



NB. =========================================================
NB. UNPACKING
NB. Unpack MsgPack datatypes to J datatypes
NB. =========================================================
is_in_range=: ((0&{ @ [) < ]) *. ((1&{ @ [) > ])

NB. Unpack bytes
NB. dyadic verb. x value 0 or 1. 0 = unpack msgpack bytes, 1 = unpack json string.

unpack=: unpack_obj@:,@:hfd@:(a.&i.)

NB. =========================================================
NB. UNPACK BOOLS
NB. =========================================================
unpack_true=: 1
unpack_false=: 0
unpack_nil=: 0 NB. no null in J. TODO change this to more suitable type.

NB. =========================================================
NB. UNPACK INTEGERS
NB. =========================================================
unpack_integer=: monad define
data=. y
len=. #y
if. len = 1 do. 0
elseif. len = 2 do.
  if. (0{y)e. 'ef' do.
    (dfh data) - 256
  else.
    dfh data
  end.
elseif. (2{.y) -: 'cc' do. '' $ dfh strip2 data
elseif. (2{.y) -: 'cd' do. '' $ dfh strip2 data
elseif. (2{.y) -: 'ce' do. '' $ dfh strip2 data
elseif. (2{.y) -: 'cf' do. '' $ dfh strip2 data
elseif. (2{.y) -: 'd0' do. '' $ 1 dfh_unstretch strip2 data
elseif. (2{.y) -: 'd1' do. '' $ 2 dfh_unstretch strip2 data
elseif. (2{.y) -: 'd2' do. '' $ 4 dfh_unstretch strip2 data
elseif. (2{.y) -: 'd3' do. '' $ 8 dfh_unstretch strip2 data
end.
)

NB. Take the first two items
take2=: 2&{.
NB. Strip the front 2 chars from the front of the array
strip2=: 2&}.
NB. Reshapes the hexstring into a 4x2 array of hex strings,
NB. representing bytes.
byte_shape=: 2&(,~)@:-:@:# $ ]
NB. Gets a J float from the hex string
floatFromHex=: _2&(3!:5)@:|.@:(a.&({~))@:dfh@:byte_shape

NB. =========================================================
NB. UNPACK FLOATS
NB. =========================================================
unpack_float=: monad define
result=. ''
if. (2{.y) -: float64 do.
  result=. '' $ floatFromHex 16 {. strip2 y
elseif.1 do. result=. '' $  floatFromHex 8 {. strip2 y
end.
)

NB. =========================================================
NB. UNPACK STRINGS
NB. =========================================================
unpack_string=: monad define
type=. take2 y
len=. ''
if. type -: str8 do. len=. 4
elseif. type -: str16 do. len=. 6
elseif. type -: str32 do. len=. 10
elseif. 1 do.
  len=. 2
end.
result=. a.{~ dfh byte_shape len }. y
result
NB. ====== TOD0 =====
NB. for json, need to enclose strings in double quotes
NB. =========================================================
)

NB. =========================================================
NB. UNPACK BINARY
NB. =========================================================
unpack_bin=: monad define
if.(2{.y) -: bin8 do. (dfh 2{. strip2) y
elseif. (2{.y) -: bin16 do. (dfh 4{. strip2 y
elseif. (2{.y) -: bin32 do. (dfh 8{. strip2 y
end.
)

NB. =========================================================
NB. UNPACK MAPS
NB. =========================================================
unpack_map=: monad define
if. (2<{.y) e. (map16; map32) do.
  len=. dfh 4{. strip2 y
  result=. < unpack_obj len {. strip2 y
end.
result
)


NB. Gives the number of chars to take from the
NB. argument to parse in the next deserialization call.
length=: monad define
type=. take2 y
len=. _1
NB. strings
if. ({.type) e.'ab' do. len=. 2*(dfh>type)-160
elseif. type-:str8 do.
  len=. 2+2*dfh (2 3{y)
elseif. type-:str16 do. len=. 4+2*dfh(2+i.4){y
elseif. type-:str32 do. len=. 8+2*dfh(2+i.8){y
NB. boolean
elseif. type-:true do. len=. 0
elseif. type-:false do. len=. 0
NB. integers
elseif. (dfh{.type) < 8 do. len=. 0
elseif. (0{type)e.'ef' do. len=. 0
elseif. type-:uint8 do. len=. 2
elseif. type-:uint16 do. len=. 4
elseif. type-:uint32 do. len=. 8
elseif. type-:uint64 do. len=. 16
elseif. type-:int8 do. len=. 2
elseif. type-:int16 do. len=. 4
elseif. type-:int32 do. len=. 8
elseif. type-:int64 do. len=. 16
NB. floats
elseif. type-:float32 do. len=. 8
elseif. type-:float64 do. len=. 16
elseif. (dfh{.type)=9 do. len=. dfh 1{type NB. second hex digit is length
  len=. get_len (strip2 y);len
elseif. type-:array16 do. len=. dfh 4{.strip2 y
  len=. 4+get_len (strip2 y);len
elseif. type-:array32 do. len=. dfh 8{.strip2 y
  len=. 8+get_len (strip2 y);len
NB. map
elseif. 1 do. len=. dfh 1{type
  len=. get_map_len (strip2 y);len
end.
len+2 NB. add the prefix byte.
)

NB. Unpacks a byte string into J objects.
NB. Any arrays will be unpacked into J boxed arrays
NB.
unpack_obj=: monad define
data =. tolower ' '-.~ y
type=. take2 data
len=. _1
if. 0 = # data do.
elseif.type-:true do. 1
elseif.type-:false do. 0
NB. strings
elseif. ({. type) e.'ab' do. unpack_string data
elseif. (<type) e. str8;str16;str32 do. unpack_string data
NB. integers
elseif. (dfh{.type) < 8 do. unpack_integer data
elseif. (0{type) e.'ef' do. unpack_integer data
elseif. (<type) e. uint8;uint16;uint32;uint64;int8;int16;int32;int64 do. unpack_integer data
NB. floats
elseif. (<type) e. float32;float64 do. unpack_float data
NB. binary
elseif. (<type) e. bin8;bin16;bin32 do. unpack_bin data
NB. arrays
elseif. (dfh{.type) = 9 do. len=. dfh (1{type) NB. second hex digit is length
  read_len (strip2 data);len
elseif. type -: array16 do. len=. (dfh 4{.strip2 data)
  read_len (4}. strip2 data);len
elseif. type -: array32 do. len=. (dfh 8{.strip2 data)
  read_len  (8}.strip2 data);len
NB. Maps
elseif. (dfh 0{type) = 8 do. NB. fixed map
  len=. dfh (1{type)
  read_map_len  (strip2 data);len
elseif. type -: map16 do. len=. (dfh 4{.strip2 data)
  read_map_len  (4}. strip2 y);len
elseif. type -: map32 do. len=. (dfh 8{.strip2 data)
  read_map_len  (8}.strip2 data);len
elseif. 1 do.
  1
end.
)


NB. takes the bytes to be read and the length to read.
NB. returns the unpacked bytes and the remaining bytes to be read.
read=: >@(1&{@]) (unpack_obj@{.;}.) >@(0&{@])


NB. read data and return the unpacked data
NB. with the length of the bytes that were read.
read_len=: verb define
data=. >0{y
len=. >1{y
reslt=. ''
shape =. 1
while. len > 0 do.
  k=. length data
  box=. read data;k
  reslt=. reslt, 0{ box
  data=. >1{box
  len=. len - 1
end.
reslt
)



NB. Reads the Map datatype into a J implemented
NB. Map object. Returns the symbolized object reference
NB. of the map.
read_map_len=: verb define
hMap=. conew 'HashMap'
create__hMap ''
data=. >0{y
len=. 2 * >1{y NB. two objects , because map.
isKey=. 1 NB. key or value
key=. ''
while. len > 0 do.
  k=. length data
  box=. read data;k
  if. isKey do.
    key=. (>0{ box )
  else.value=. 0{ box
    if. 'HashMap' -: get_type value do.
      set__hMap key;value
    else.
      set__hMap key;<value
    end.
  end.
  data=. >1{box
  len=. len - 1
  isKey=. 2 | (isKey + 1)
end.
s: hMap
)



NB. Gets the length in bytes of the
NB. packed array.
get_len=: verb define
data=. >0{y
len=. >1{y
totallen=. 0
reslt=. ''
while. len > 0 do.
  k=. length data
  totallen=. totallen + k
  box=. read data;k
  reslt=. reslt, 0{ box
  data=. >1{box
  len=. len - 1
end.
totallen
)



