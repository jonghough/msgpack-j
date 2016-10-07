NB. ==================================
NB. Some utility verbs etc.
NB. ==================================

NB. generate lots of keyvalue pairs for
NB. hashmap testing
list=: ('key'&,@:([: ": ]))"_ 0 ( i.45)
listX=: list;"1 1 ('something',"_ 1 list)


NB. inserts spaces in hexstring
insert_spaces=:  (] #~ 1 1j1 $~ #)

NB. Gets the type (datatype)
get_type =: 3 : 0
dt =. datatype y
if. dt -: 'symbol' do. 'HashMap'
else. dt end.
)

NB. bit operators
(XOR=: 22 b.),(OR=: 23 b.),(AND=: 17 b.),(NOT=: 20 b.),(SHIFT=: 33 b.)

NB. for JSON functions
wrap_with =: [,~ ([,])
insert =: [,(','&,@:])