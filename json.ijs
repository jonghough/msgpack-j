NB. Json to J deserialization

CURLY_OPEN=.0
CURLY_CLOSE=.1
BOX_OPEN=.2
BOX_CLOSE=.3
COMMA=.4
COLON=.5
QUOTE=.6
NUMBER=.7
TRUE=.8
FALSE=.9
NULL=.10

deserialize=: monad define
NT=. 0{y
while. 1 do.
if. NT -: '{' do.
deserializeMap 0{.y
elseif. NT -: '[' do.
deserializeArray 0{.y
elseif. NT -: '"' do.
deserializeString 0{.y
)


deserializeMap=. monad define
NT =. 1{y NB. 0{y must be '{'
c =. 1
t =. y
res =. ''
while. 0 = NT -: ',' do.
key =. ''
value =. ''
c =. c+1
NT =. c{y
if. 0 = NT -: ':'
key =. key , 
)

getNextElement=. monad define
hasElement=. 0
str=. y
ctr=.0
next =.''
while. hasElement = 0 do.
	e=.ctr{str
	if. e -: QUOTE do. deserializeString str
	else. next
)