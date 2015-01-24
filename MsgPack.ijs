NB. J implementation of MsgPack
NB. @author Jon Hough


NB. SPECIFICATION
NB. https://github.com/msgpack/msgpack/blob/master/spec.md

NB. BYTE PREFIXES - constants
nil 	=: 'c0'
reserved 	=: 'c1'
false 	=: 'c2'
true 	=: 'c3'
bin8 	=: 'c4'
bin16 	=: 'c5'
bin32 	=: 'c6'
ext8 	=: 'c7'
ext16 	=: 'c8'
ext32 	=: 'c9'
float32 	=: 'ca'
float64 	=: 'cb'
uint8 	=: 'cc'
uint16 	=: 'cd'
uint32 	=: 'ce'
uint64 	=: 'cf'
int8 	=: 'd0'
int16 	=: 'd1'
int32 	=: 'd2'
int64 	=: 'd3'
fixext1 	=: 'd4'
fixext2 	=: 'd5'
fixext4 	=: 'd6'
fixext8 	=: 'd7'
fixext16 	=: 'd8'
str8 	=: 'd9'
str16 	=: 'da'
str32 	=: 'db'
array16 	=: 'dc'
array32 	=: 'dd'
map16 	=: 'de'
map32 	=: 'df'

XOR 	=: 22 b.
OR 	=: 23 b.
AND 	=: 17 b.
NOT 	=: 20 b.


NB. can be represented as single byte
isSmallUInt =: (=(127&AND))*.(0&<)
isSmallNegInt =: (=(32&AND))*.(0&>)


pad1Byte =: ((($&0)@:(8&-)@#),])@:#:
digitsToString =: ,"2@:(":"0)

NB. Same as hfd, but prepends a leading
NB. '0' onto hex strings with odd number of 
NB. characters.
hfd2 =: verb define 
h=: hfd y
len =: # h
result =: h
if. (2 | len) = 1 do.
result =: '0',result
end.
result
)

hfd_stretch =: dyad define
targetLen =. x
h =: hfd2 y
result =: h
diff =: targetLen - (2 %~ # h)
if. diff > 0 do.
append =: (2*diff) $ '0'
result =: append, result
end.
result
)
NB. serialize int data type

serializeInt =: verb define

result =: ''

if. isSmallUInt y do.

result =: pad1Byte

end.

)

NB. ==============================
NB. PACK INTEGERS
NB. ==============================

packInteger =: verb define
result =: ''
if. y < 0 do.
	if. (y-1) > _32 do. NB. 5 bits 111YYYYY form
		p =: 224
		p =: 1 (3!:4) y
		p =: a.i. p
		p =: 0{ hfd p
		result =: p NB. hfd2 p OR y
	elseif. (y-1) > _128 do. 
		result =: int8, hfd2 y
	elseif. (y-1) > (2^15) do.
		result  =: int16, hfd2 y
	elseif. (y-1) > (2^31) do.
		result =: int32, hfd2 y
	elseif. (y-1) > (2^63) do.
		result =: int64, hfd2 y
	elseif. 1 do.
	NB. NOTHING
		1
	end.
elseif. 1 do.
	if. (y-1) < 127 do.
		result =: hfd2 y
	elseif. (y-1) < 256 do.
		result =: uint8, (1 hfd_stretch y)
	elseif. (y-1) < (2^16) do.
		result =: uint16, (2 hfd_stretch y)
	elseif. (y-1) < (2^32) do.
		result =: uint32, (4 hfd_stretch y)
	elseif. (y-1) < (2^64) do.
		result =: uint64, (8 hfd_stretch y)
	elseif. 1 do.
		1
	end.
end.
result
)
pi =: packInteger


NB. ====================================
NB. PACK FLOATS
NB. ====================================
convertFloat =: |."1@:,@:(|."1)@:hfd@:(a.&i.)@:(2&(3!:5))

packFloat =: verb define
result =: ''
result =: float64, convertFloat y
result
)


NB. ====================================
NB. PACK STRINGS
NB. ====================================
cs =: st =: , @: hfd @: (a.&i.)

packString =: verb define
result =: ''
hexStr =: cs y
len =. 2%~ # hexStr
smoutput len
if. len < 32 do. # NB.  Up to 32 bytes
	pre =. hfd2 160 OR len
	result =: pre, hexStr
elseif. len < 2^8 do.
	pre =.str8
	result =: pre, (1 hfd_stretch len), hexStr
elseif. len < 2^16 do.
	pre =.str16
	result =: pre, (2 hfd_stretch len), hexStr
elseif. len < 2^32 do.
	pre =.str32
	result =: pre, (4 hfd_stretch len), hexStr
elseif. 1 do. 
	1
end.
result
)

NB. ====================================
NB. PACK ARRAYS
NB. ====================================
packArray =: verb define
result =: ''
hexArr =: packFloat"0 y
len =: # hexArr
if.len < 16 do.
	pre =: hfd2 149 OR len NB. 1001XXXX
	result =: pre, (,hexArr)
elseif. len < 2^16 do.
	pre =.array16
	result =: pre, (2 hfd_stretch len), (,hexArr)
end.
)