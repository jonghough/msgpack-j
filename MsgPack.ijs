NB. J implementation of MsgPack
NB. @author Jon Hough

NB. BYTE PREFIXES - constants
(nil=:'c0'),(reserved=:'c1'),(false=:'c2'),(true=:'c3'),(bin8=:'c4'),(bin16=:'c5'),(bin32=:'c6'),(ext8=:'c7'),(ext16=:'c8')
(ext32=:'c9'),(float32=:'ca'),(float64=:'cb'),(uint8=:'cc'),(uint16 =:'cd'),(uint32 =:'ce'),(uint64 =:'cf'),(int8 =:'d0'),(int16=:'d1')
(int32=:'d2'),(int64=:'d3'),(fixext1=:'d4'),(fixext2=:'d5'),(fixext4=:'d6'),(fixext8=:'d7'),(fixext16=:'d8'),(str8=:'d9'),(str16=:'da')
(str32=:'db'),(array16=:'dc'),(array32=:'dd'),(map16=:'de'),(map32=:'df')

NB. operators
(XOR =: 22 b.),(OR =: 23 b.),(AND =: 17 b.),(NOT =: 20 b.)

NB. can be represented as single byte
isSmallUInt =: (=(127&AND))*.(0&<)
isSmallNegInt =: (=(32&AND))*.(0&>)
isBoxed =: 0&<@:L.
digitsToString =: ,"2@:(":"0)

NB. Same as hfd, but prepends a leading
NB. '0' onto hex strings with odd number of
NB. characters.
hfd2 =: monad define
h=. hfd y
len =. # h
result =. h
if. (2 | len) = 1 do.
if. y < 0 do. result =. 'f',result
else. result =. '0',result end.
end.
result
)


NB. Calculates hex from decimal
NB. and stretches the number of bytes to the
NB. required amount, either padding 0's or F's
hfd_stretch =: dyad define
targetLen =. x
h =. hfd2 y
result =. h
diff =. targetLen - (2 %~ # h)
if. diff > 0 do.
if. y < 0 do. append =. (2*diff) $ 'f'
else. append =. (2*diff) $ '0' end.
result =. append, result
end.
result
)


NB. ==============================
NB. PACK AN OBJECT
NB. ==============================
packObj =: monad define
result =. ''
boxy =. < datatype y
len =. # y
shape =. $ y
if. isBoxed y do. result =. packBox y
elseif. boxy = < 'literal' do. result =. packString y
elseif. (# shape) > 1 do.
prefix =. hfd2 144 OR {. shape
ord =. 0&>.<:#shape
result =. ' '-.~,"_ prefix, (packObj"ord ) y NB. TODO need to add prefix to show the length of the overall array.
elseif. len > 1 do. result =. ' '-.~,"_ packArray y
elseif. boxy e. ( 'integer' ; 'boolean') do. result =. packInteger y
elseif. boxy = < 'floating' do. result =. packFloat y
end.
result
)


NB. ==============================
NB. PACK INTEGERS
NB. ==============================
convertInt =: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:4))
packInteger =: monad define
result =. ''
if. y < 0 do.
if. (y-1) > _32 do. NB. 5 bits 111YYYYY form
result =. 1 hfd_stretch y
elseif. (y-1) > _128 do.
result =. int8, (1 hfd_stretch y)
elseif. (y-1) > (_1*2^16) do.
result =. int16, (2 hfd_stretch y)
elseif. (y-1) > (_1*2^32) do.
result =. int32, (4 hfd_stretch y)
elseif. (y-1) > (_1*2^64) do.
result =. int64, (8 hfd_stretch y)
elseif. 1 do.
NB. NOTHING
1
end.
elseif. 1 do.
if. (y+1) < 127 do.
result =. hfd2 y
elseif. (y+1) < 256 do.
result =. uint8, (1 hfd_stretch y)
elseif. (y+1) < (2^16) do.
result =. uint16, (2 hfd_stretch y)
elseif. (y+1) < (2^32) do.
result =. uint32, (4 hfd_stretch y)
elseif. (y+1) < (2^64) do.
result =. uint64, (8 hfd_stretch y)
elseif. 1 do.
1
end.
end.
result
)

NB. ====================================
NB. PACK FLOATS
NB. ====================================
convertFloat =: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:5))
packFloat =: monad define
result =. ''
if. (=<.) y do. result =. packInteger y NB. if can be cast to integer then pack as an integer.
elseif. 1 do. result =. float64, convertFloat y
end.
result
)

NB. ====================================
NB. PACK STRINGS
NB. ====================================
cs =: , @: hfd @: (a.&i.)

packString =: monad define
result =. ''
hexStr =. cs y
len =. 2%~ # hexStr
if. len < 32 do. # NB. Up to 32 bytes
pre =. hfd2 160 OR len
result =. pre, hexStr
elseif. len < 2^8 do.
pre =.str8
result =. pre, (1 hfd_stretch len), hexStr
elseif. len < 2^16 do.
pre =.str16
result =. pre, (2 hfd_stretch len), hexStr
elseif. len < 2^32 do.
pre =.str32
result =. pre, (4 hfd_stretch len), hexStr
elseif. 1 do.
1
end.
result
)



NB. ====================================
NB. PACK ARRAYS
NB. ====================================
packArray =: monad define
result =. ''
hexArr =. ' '-.~ packObj"0 y NB. pack the items
len =. # hexArr
if.len < 16 do.
pre =. hfd2 144 OR len NB. 1001XXXX
result =. ' '-.~ , pre, (hexArr)
elseif. len < 2^16 do.
pre =.array16
result =. pre, (2 hfd_stretch len), (,hexArr)
end.
)

NB. ====================================
NB. PACK BOX
NB. ====================================
packBox =: verb define
result =. ''
len =. # y
if. len = 1 do. result =. packObj > y
else.
if.len < 16 do.
pre =. hfd2 144 OR len
ord =. 0&>.<:#$ y
result =. ' '-.~ , pre, (, packBox"ord y)
elseif. len < 2^16 do.
pre =.array16
ord =. 0&>.<:#$ y
result =. ' '-.~ pre, (2 hfd_stretch len), (, packBox"ord y)
end.
end.
result
)


NB. ====================================
NB. PACK NIL
NB. probably pointless
NB. ====================================
packNil =: nil

NB. Pack -> Int array, char.
pack =: (a.&({~))@:dfh@:byteShape@:packObj

NB. ====================================
NB. UNPACKING
NB. Unpack MsgPack datatypes to J datatypes
NB. ====================================
isInRange =: ((0&{ @ [) < ]) *. ((1&{ @ [) > ])

NB. Unpack... not finished.
unpackObj =: monad define
result =. ''
if. 2 = # y do. result =: unpackInteger y
else.
b1 =. <take2 y
if. b1 = <false do.
result =. 0 NB. A false representation in J
elseif. b1 = <true do.
result =. 1
elseif. b1 e. uint8;uint16;uint32;uint64;int8;int16;int32;int64 do.
result =. unpackInteger y
elseif. (b1 e. str8;str16;str32)+. (159 176 isInRange dfh > b1) do.
result =. unpackString y
elseif. 1 do.
1
end.
if. 2 > # strip2 y do.
result =. result ; (unpackObj strip2 y) NB. TODO, should be boxed?
end.
end.
result
)


NB. ====================================
NB. UNPACK BOOLS
NB. ====================================

unpackTrue =: 1
unpackFalse =: 0
unpackNil =: 0 NB. no null in J. TODO change this to more suitable type.


NB. ====================================
NB. UNPACK INTEGERS
NB. ====================================

NB. todo - finish for all integer lengths int/uint
unpackInteger =: monad define
result =. ''
data =. y
len=. #y
if. len = 2 do. result =. dfh data
elseif. (<2{.y) = <'cc' do. result =. dfh strip2 data
elseif. (<2{.y) = <'cd' do. result =. dfh strip2 data
elseif. (<2{.y) = <'ce' do. result =. dfh strip2 data
elseif. (<2{.y) = <'cf' do. result =. dfh strip2 data
end.
result
)


NB. Take the first two items
take2 =: 2&{.
NB. Strip the front 2 chars from the front of the array
strip2 =: 2&}.
NB. Reshapes the hexstirng into a 4x2 array of hex stirngs,
NB. representing bytes.
byteShape =: 2&(,~)@:(2&(%~))@:# $ ]
NB. Gets a J float from the hex string

floatFromHex =: _2&(3!:5)@:|.@:(a.&({~))@:dfh@:byteShape

NB. ====================================
NB. UNPACK FLOATS
NB. ====================================
unpackFloat =: monad define
result =. ''
if. (<2{.y) = < float64 do.
result =. floatFromHex 16 {. strip2 y
elseif.1 do. result =. floatFromHex 8 {. strip2 y
end.
)


NB. ====================================
NB. UNPACK STRINGS
NB. ====================================
unpackString =: monad define
type =. < take2 y
len =. ''
if. type = <str8 do. len =. 4
elseif. type = <str16 do. len =. 6
elseif. type = <str32 do. len =. 10
elseif. 1 do.
len =. 2
end.
result =. a.{~ dfh byteShape len }. y
result
)


unpackBin =: monad define

)


unpackMap =: monad define
if. (2<{.y) e. (map16; map32) do.
len =. dfh 4{. strip2 y
result =. < unpackObj len {. strip2 y
end.
result
)



unpackArray =: monad define
result =.length y
result
)


NB. Gives the number of chars to take from the
NB. argument to parse in the next deserialization call.
length =: monad define
type =. < take2 y
len =. _1

NB. strings
if. ({. > type) e.'ab' do. len =. 2* (dfh > type) - 160
elseif. type = <str8 do.
smoutput 'y ',":y
len =.2+2* dfh (2 3{y)
elseif. type = <str16 do. len =.4+ 2*dfh (2 3 4 5{y)
elseif. type = <str32 do. len =.8+ 2*dfh (2 3 4 5 6 7 8 9{y)
NB. integers
elseif. (dfh{.>type) < 8 do. len =. 0
elseif. type = <uint8 do. len =. 2
elseif. type = <uint16 do. len =. 4
elseif. type = <uint32 do. len =. 8
elseif. type = <uint64 do. len =. 16
elseif. type = <int8 do. len =. 0
elseif. type = <int16 do. len =. 4
elseif. type = <int32 do. len =. 8
elseif. type = <int64 do. len =. 16
NB. floats
elseif. type = <float32 do. len =. 8
elseif. type = <float64 do. len =. 16
elseif. (dfh{.>type) = 9 do. len =. dfh ( 1{ > type) NB. second hex digit is length
len=. getLen (strip2 y);len
elseif. type = <array16 do. len =.  ( dfh 4{. strip2 y)
len=. getLen 4}.(strip2 y);len
elseif. type = <array32 do. len =. (dfh 8{. strip2 y)
len=. getLen 8}.(strip2 y);len
end.
res=. len+2
res
)


unpack =: monad define
type =. < take2 y
len =. _1
func =. ''
res =. ''
if. 0 = # y do.
NB. strings
elseif. ({. > type) e.'ab' do. NB.len =.2+2* (dfh > type) - 160
res =. unpackString y
elseif. type = <str8 do. NB.len =.dfh (2 3{y)
res =. unpackString y
elseif. type = <str16 do. NB.len =.dfh (2 3 4 5{y)
res =. unpackString y
elseif. type = <str32 do. NB.len =.dfh (2 3 4 5 6 7 8 9{y)
res =. unpackString y
NB. integers
elseif. (dfh{.>type) < 8 do. len =.2+ 0
res =. unpackInteger y
elseif. type = <uint8 do. len =. 2+2
res =. unpackInteger y
elseif. type = <uint16 do. len =.2+ 4
res =. unpackInteger y
elseif. type = <uint32 do. len =.2+ 8
res =. unpackInteger y
elseif. type = <uint64 do. len =.2+ 16
res =. unpackInteger y
elseif. type = <int8 do. len =.2+ 0
res =. unpackInteger y
elseif. type = <int16 do. len =.2+ 4
res =. unpackInteger y
elseif. type = <int32 do. len =.2+ 8
res =. unpackInteger y
elseif. type = <int64 do. len =.2+ 16
res =. unpackInteger y
NB. floats
elseif. type = <float32 do. len =.2+ 8
res =.unpackFloat y
elseif. type = <float64 do. len =. 2+16
res =.unpackFloat y
NB. arrays
elseif. (dfh{.>type) = 9 do. len =. dfh ( 1{ > type) NB. second hex digit is length
res =.readLen (strip2 y);len
elseif. type = <array16 do. len =. ( dfh 4{. strip2 y)
res =.readLen (4}. strip2 y);len
elseif. type = <array32 do. len =. (dfh 8{. strip2 y)
res =.readLen (8}.strip2 y);len
end.
res
)



NB. takes the bytes to be read and the length to read.
NB. returns the unpacked bytes and the remaining bytes to be read.
read =: verb define
bytes =. >0{y
len =. >1{y
(unpack len {. bytes);(len}.bytes)
)

NB. tacit read
rd =: >@(1&{@]) (unpack@{.;}.) >@(0&{@])


readLen =: verb define
data =. >0{y
len =. >1{y
reslt=. ''
while. len > 0 do.
k =. length data
box =. read data;k
reslt =. reslt, 0{ box
data =. >1{box
len =. len - 1
end.
reslt
)

getLen =: verb define
data =. >0{y
len =. >1{y
totalLen =. 0
reslt=. ''
while. len > 0 do.
k =. length data
totalLen =. totalLen + k
box =. read data;k
reslt =. reslt, 0{ box
data =. >1{box
len =. len - 1
end.
totalLen
)