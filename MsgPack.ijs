NB. J implementation of MsgPack
NB. @author Jon Hough
NB.

require '~user/projects/MsgPack/msgpack-j/utils.ijs'

NB. BYTE PREFIXES - constants
(nil=: 'c0'),(reserved=: 'c1'),(false=: 'c2'),(true=: 'c3'),(bin8=: 'c4'),(bin16=: 'c5'),(bin32=: 'c6'),(ext8=: 'c7'),(ext16=: 'c8')
(ext32=: 'c9'),(float32=: 'ca'),(float64=: 'cb'),(uint8=: 'cc'),(uint16=: 'cd'),(uint32=: 'ce'),(uint64=: 'cf'),(int8=: 'd0'),(int16=: 'd1')
(int32=: 'd2'),(int64=: 'd3'),(fixext1=: 'd4'),(fixext2=: 'd5'),(fixext4=: 'd6'),(fixext8=: 'd7'),(fixext16=: 'd8'),(str8=: 'd9'),(str16=: 'da')
(str32=: 'db'),(array16=: 'dc'),(array32=: 'dd'),(map16=: 'de'),(map32=: 'df')

NB. decimal prefixes -TODO replace above byte prefix strings with these.
(nilD=:192),(reservedD=:193),(falseD=:194),(trueD=:195),(bin8D=:196)
(bin16D=:197),(bin32D=:198),(ext8D=:199),(ext16D=:200),(ext32D=:201)
(float32D=:202),(float64D=:203),(uint8D=:204),(uint16D=:205),(uint32D=:206)
(uint64D=:207),(int8D=:208),(int16D=:209),(int32D=:210),(int64D=:211)
(fixext1D=:212),(fixext2D=:213),(fixext4D=:214),(fixext8D=:215),(fixext16D=:216)
(str8D=:217),(str16D=:218),(str32D=:219),(array16D=:220),(array32D=:221),(map16D=:222),(map32D=:223)

isBoxed=: 0&<@:L.

NB. Same as hfd, but prepends a leading
NB. '0' onto hex strings with odd number of
NB. characters.
hfd2=: hfd`(('f'&,@hfd)`('0'&,@hfd)@.(0&<))@.(2&|@#@hfd)

NB. Calculates hex from decimal
NB. and stretches the number of bytes to the
NB. required amount, either padding 0's or F's
hfd_stretch=: dyad define
targetLen=. x
h=. hfd2 y
result=. h
diff=. targetLen - (-: # h)
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
packObj=: monad define
result=. ''
dt =. GetType y
if. dt -: 'HashMap' do.
packMap y
else.
boxy=. < datatype y
len=. # y
shape=. $ y
if. isBoxed y do. result=. packBox y
elseif. boxy = < 'literal' do. result=. packString y
elseif. (# shape) > 1 do.
  prefix=. hfd2 144 OR {. shape
  ord=. 0&>.<:#shape
  result=. ' '-.~,"_ prefix, (packObj"ord ) y 
elseif. len > 1 do. result=. ' '-.~,"_ packArray y
elseif. boxy e. ( 'integer' ; 'boolean') do. result=. packInteger y
elseif. boxy = < 'floating' do. result=. packFloat y
end.
result
end.
)


packObjJSON=: monad define
result=. ''
dt=. GetType y
if. dt -: 'HashMap' do.
  packMapJSON y
else.
  boxy=. < datatype y
  len=. # y
  shape=. $ y
  if. isBoxed y do. result=. packBoxJSON y
  elseif. boxy = < 'literal' do. result=. packStringJSON y
  elseif. (# shape) > 1 do.
    prefix=. hfd2 144 OR {. shape
    ord=. 0&>.<:#shape
    result=. '[',( insert/ (packObjJSON"ord ) y) , ']'
  elseif. len > 1 do. result=. ' '-.~,"_ packArrayJSON y
  elseif. boxy e. ( 'integer' ; 'boolean') do. result=. packIntegerJSON y
  elseif. boxy = < 'floating' do. result=. packFloatJSON y
  end.
  result
end.
)


NB. =========================================================
NB. PACK INTEGERS
NB. =========================================================
convertInt=: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:4))
packInteger=: monad define

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

packIntegerJSON=: ":`('-'&,@":@-)@.(0&>)


NB. =========================================================
NB. PACK FLOATS
NB. =========================================================
convertFloat=: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:5))
packFloat=: monad define
if. (=<.) y do. packInteger y NB. if can be cast to integer then pack as an integer.
elseif. 1 do. float64, convertFloat y
end.
)

packFloatJSON=: ('-'&,@":@-)`":@.(0&<)

NB. =========================================================
NB. PACK STRINGS
NB. =========================================================
convertString=: , @: hfd @: (a.&i.)
NB. pack strings to msgpack
packString=: monad define
hexStr=. convertString y
len=. 2%~ # hexStr
if. len < 32 do. # NB. Up to 32 bytes
  pre=. hfd2 160 OR len
  pre, hexStr
elseif. len < 2^8 do.
  str8 , (2 hfd_stretch len), hexStr
elseif. len < 2^16 do.
  str16 , (4 hfd_stretch len), hexStr
elseif. len < 2^32 do.
  str32 , (8 hfd_stretch len), hexStr
elseif. 1 do.
  1
end.
)

NB. pack strings to JSON
packStringJSON=: ('"'&wrapWith)@:,@:":

NB. =========================================================
NB. PACK ARRAYS
NB. =========================================================
packArray=: monad define
hexArr=. ' '-.~ packObj"0 y NB. pack the items
len=. # hexArr
if.len < 16 do.
  pre=. hfd2 144 OR len NB. 1001XXXX
  ' '-.~ , pre, (hexArr)
elseif. len < 2^16 do.
  array16 , (2 hfd_stretch len), (,hexArr)
end.
)

packArrayJSON=: monad define
len=. # y NB. pack the items
res=. '['
for_j. i. len do.
  if. j = 0 do. res=. res,packObjJSON j{ y else.
    res=. res,',',packObjJSON j{y
  end.
end.
res,']'
)

NB. =========================================================
NB. PACK BOX
NB. =========================================================
packBox=: monad define
len=. # y
if. len = 1 do. packObj > y
else.
  if.len < 16 do.
    pre=. hfd2 144 OR len
    ord=. 0&>.<:#$ y
    ' '-.~ , pre, (, packBox"ord y)
  elseif. len < 2^16 do.
    ord=. 0&>.<:#$ y
    ' '-.~ array16 , (2 hfd_stretch len), (, packBox"ord y)
  end.
end.
)


packBoxJSON=: monad define
len=. # y
if. len = 1 do. packObjJSON > y
else.
  res=. '['
  for_j. i. len do.
    if. j = 0 do. res=. res,packBoxJSON j{y
    else. res=. res , ',', packBoxJSON j{ y
    end.
  end.
  res,']'
end.
)

NB. =========================================================
NB. PACK BIN
NB. =========================================================
packBin=: monad define
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
packNil=: nil

NB. =========================================================
NB. PACK MAP
NB. packs map objects. (Map reference datatypes MUST be symbols
NB. =========================================================
packMap=: monad define
hMap=. 5 s: y NB. hashmap
NB. following two lines are a workaround for what may be a bug
NB. with J. Otherwise occassionally get rank error
NB. with size__hMap ''
str=. ,>hMap
hMap=. <str
size=. size__hMap ''
prefix=. '8', hfd size
NB. packUp will pack the key and the value of kvp pair and append them.
packUp=. (packObj, (packObj@:get__hMap@:":))@:(>@:(0&{))@:,@:>
l=. enumerate__hMap ''
a=. (' '-.~,(packUp"0) l)
prefix , a

)

packMapJSON=: monad define
hMap=. 5 s: y NB. hashmap
NB. following two lines are a workaround for what may be a bug
NB. with J. Otherwise occassionally get rank error
NB. with size__hMap ''
str=. ,>hMap
hMap=. <str
size=. size__hMap ''
prefix=. '{'
res=. ''
l=. enumerate__hMap ''

NB. packUp will pack the key and the value of kvp pair and append them.
for_j. i. size do.
  open=. (>@:(0&{))@:,@:> j{ l
  if. j = 0 do.
    res=. res , (packObjJSON open), ':' , (,@:packObjJSON@:get__hMap open)
  else.
    res=. res , ',' , (packObjJSON open), ':' , (packObjJSON@:get__hMap open)
  end.
end.
'{' , res, '}'
)

NB. Pack bytes
NB. dyadic verb. x value 0 or 1. 0 = pack msgpack bytes, 1 = pack json string.
pack=: packObjJSON@:]`(a.&({~)@:dfh@:byteShape@:packObj@:])@.(0&=@:[)


NB. =========================================================
NB. UNPACKING
NB. Unpack MsgPack datatypes to J datatypes
NB. =========================================================
isInRange=: ((0&{ @ [) < ]) *. ((1&{ @ [) > ])

NB. Unpack bytes
NB. dyadic verb. x value 0 or 1. 0 = unpack msgpack bytes, 1 = unpack json string.
unpack=: unpackObjJSON@:,@:hfd@:(a.&i.)@:]`(unpackObj@:,@:hfd@:(a.&i.)@:])@.(0&=@:[)

NB. =========================================================
NB. UNPACK BOOLS
NB. =========================================================
unpackTrue=: 1
unpackFalse=: 0
unpackNil=: 0 NB. no null in J. TODO change this to more suitable type.

NB. =========================================================
NB. UNPACK INTEGERS
NB. =========================================================
unpackInteger=: monad define
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
byteShape=: 2&(,~)@:(2&(%~))@:# $ ]
NB. Gets a J float from the hex string
floatFromHex=: _2&(3!:5)@:|.@:(a.&({~))@:dfh@:byteShape

NB. =========================================================
NB. UNPACK FLOATS
NB. =========================================================
unpackFloat=: monad define
result=. ''
if. (2{.y) -: float64 do.
  result=. '' $ floatFromHex 16 {. strip2 y
elseif.1 do. result=. '' $  floatFromHex 8 {. strip2 y
end.
)

NB. =========================================================
NB. UNPACK STRINGS
NB. =========================================================
unpackString=: monad define
type=. take2 y
len=. ''
if. type -: str8 do. len=. 4
elseif. type -: str16 do. len=. 6
elseif. type -: str32 do. len=. 10
elseif. 1 do.
  len=. 2
end.
result=. a.{~ dfh byteShape len }. y
result
NB. ====== TOD0 =====
NB. for json, need to enclose strings in double quotes
NB. =========================================================
)

NB. =========================================================
NB. UNPACK BINARY
NB. =========================================================
unpackBin=: monad define
if.(2{.y) -: bin8 do. (dfh 2{. strip2) y
elseif. (2{.y) -: bin16 do. (dfh 4{. strip2 y
elseif. (2{.y) -: bin32 do. (dfh 8{. strip2 y
end.
)

NB. =========================================================
NB. UNPACK MAPS
NB. =========================================================
unpackMap=: monad define
if. (2<{.y) e. (map16; map32) do.
  len=. dfh 4{. strip2 y
  result=. < unpackObj len {. strip2 y
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
  len=. getLen (strip2 y);len
elseif. type-:array16 do. len=. dfh 4{.strip2 y
  len=. 4+getLen (strip2 y);len
elseif. type-:array32 do. len=. dfh 8{.strip2 y
  len=. 8+getLen (strip2 y);len
NB. map
elseif. 1 do. len=. dfh 1{type
  len=. getMapLen (strip2 y);len
end.
len+2 NB. add the prefix byte.
)

NB. Unpacks a byte string into J objects.
NB. Any arrays will be unpacked into J boxed arrays
NB.
unpackObj=: monad define
type=. take2 y
len=. _1
if. 0 = # y do.
elseif.type-:true do. 1
elseif.type-:false do. 0
NB. strings
elseif. ({. type) e.'ab' do. unpackString y
elseif. (<type) e. str8;str16;str32 do. unpackString y
NB. integers
elseif. (dfh{.type) < 8 do. unpackInteger y
elseif. (0{type) e.'ef' do. unpackInteger y
elseif. (<type) e. uint8;uint16;uint32;uint64;int8;int16;int32;int64 do. unpackInteger y
NB. floats
elseif. (<type) e. float32;float64 do. unpackFloat y
NB. binary
elseif. (<type) e. bin8;bin16;bin32 do. unpackBin y
NB. arrays
elseif. (dfh{.type) = 9 do. len=. dfh (1{type) NB. second hex digit is length
  readLen (strip2 y);len
elseif. type -: array16 do. len=. (dfh 4{.strip2 y)
  readLen (4}. strip2 y);len
elseif. type -: array32 do. len=. (dfh 8{.strip2 y)
  readLen  (8}.strip2 y);len
NB. Maps
elseif. (dfh 0{type) = 8 do. NB. fixed map
  len=. dfh (1{type)
  readMapLen  (strip2 y);len
elseif. type -: map16 do. len=. (dfh 4{.strip2 y)
  readMapLen  (4}. strip2 y);len
elseif. type -: map32 do. len=. (dfh 8{.strip2 y)
  readMapLen  (8}.strip2 y);len
elseif. 1 do.
  1
end.
)

unpackObjJSON=: monad define
type=. take2 y
len=. _1
if. 0 = # y do.
elseif.type-:true do. 1
elseif.type-:false do. 0
NB. strings
elseif. ({.type) e.'ab' do. unpackString y
elseif. (<type) e. str8;str16;str32 do. unpackString y
NB. integers
elseif. (dfh{.type) < 8 do. unpackInteger y
elseif. (0{type) -: 'ef' do. unpackInteger y
elseif. (<type) e. uint8;uint16;uint32;uint64;int8;int16;int32;int64 do. unpackInteger y
NB. floats
elseif. (<type) e. float32;float64 do. unpackFloat y
NB. binary
elseif. (<type) e. bin8;bin16;bin32 do. unpackBin y
NB. arrays
elseif. (dfh{.type) = 9 do. len=. dfh (1{>type) NB. second hex digit is length
  readLenToJSON (strip2 y);len
elseif. type -: array16 do. len=. (dfh 4{.strip2 y)
  readLenToJSON (4}. strip2 y);len
elseif. type -: array32 do. len=. (dfh 8{.strip2 y)
  readLenToJSON (8}.strip2 y);len
NB. Maps
elseif. (dfh 0{type) = 8 do. NB. fixed map
  len=. dfh (1{type)
  readMapLenToJSON (strip2 y);len
elseif. type -: map16 do. len=. (dfh 4{.strip2 y)
  readMapLenToJSON (4}. strip2 y);len
elseif. type -: map32 do. len=. (dfh 8{.strip2 y)
  readMapLenToJSON (8}.strip2 y);len
elseif. 1 do.
  1
end.
)

NB. takes the bytes to be read and the length to read.
NB. returns the unpacked bytes and the remaining bytes to be read.
read=: >@(1&{@]) (unpackObj@{.;}.) >@(0&{@])

NB. read data and return the unpacked data
NB. with the length of the bytes that were read.
readLen=: verb define
data=. >0{y
len=. >1{y
reslt=. ''
while. len > 0 do.
  k=. length data
  box=. read data;k
  reslt=. reslt, 0{ box
  data=. >1{box
  len=. len - 1
end.
reslt
)

NB. Reads the given length of bytes from the data and returns JSON format representation
NB. of the data.
readLenToJSON=: verb define
data=. >0{y
len=. >1{y
reslt=. '['
while. len > 0 do.
  k=. length data
  box=. read data;k
  if. len > 1 do.
    reslt=. reslt, (":>0{ box), ','
  else. reslt=. reslt, ":>0{ box end.
  data=. >1{box
  len=. len - 1
end.
reslt,']'
)


NB. Reads the Map datatype into a J implemented
NB. Map object. Returns the symbolized object reference
NB. of the map.
readMapLen=: verb define
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
    if. 'HashMap' -: GetType value do.
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

NB. see: readMapLen.
NB. Reads bytes and returns a JSON key value pair.
readMapLenToJSON=: verb define
data=. >0{y
len=. 2 * >1{y NB. two objects , because map.
reslt=. '{'
isKey=. 1 NB. key or value
while. len > 0 do.
  k=. length data
  box=. read data;k
  if. isKey do.
    reslt=. reslt, (":>0{ box ), ':'
  else. reslt=. reslt,(":>0{ box )
    if. len > 1 do. reslt=. reslt,','end.
  end.
  data=. >1{box
  len=. len - 1
  isKey=. 2 | (isKey + 1)
end.
reslt,'}'
)

NB. Gets the length in bytes of the
NB. packed array.
getLen=: verb define
data=. >0{y
len=. >1{y
totalLen=. 0
reslt=. ''
while. len > 0 do.
  k=. length data
  totalLen=. totalLen + k
  box=. read data;k
  reslt=. reslt, 0{ box
  data=. >1{box
  len=. len - 1
end.
totalLen
)

NB. Get the length of the map
NB. i.e. number of bytes.
getMapLen=: verb define
data=. >0{y
len=. 2* >1{y
totalLen=. 0
reslt=. ''
while. len > 0 do.
  k=. length data
  totalLen=. totalLen + k
  box=. read data;k
  reslt=. reslt, 0{ box
  data=. >1{box
  len=. len - 1
end.
totalLen
)


