NB. Some tests for the MsgPack implementation
NB. require '~user/projects/MsgPack/msgpack-j/MsgPack.ijs'

NB. compare adverb.
NB. 0{n is the argument, u is the verb to be tested,
NB. 1{n is the expected result (boxed)
compare =: 2 : '((u&.>)0{n) -: (1{n)'
match =: 2 : '((u&.>)0{n) -: (((_1&*@<: @#) {. ])n)'

NB. INTEGERS TESTS
packObj compare ( 0; '00')
packObj compare ( 2; '02')
packObj compare ( 34; '22')
packObj compare ( 128; 'cc80')
packObj compare ( _128; 'd1ff80')
packObj compare ( 65536; 'ce00010000')
packObj compare ( _65536; 'd2ffff0000')
packObj compare ( 3437655; 'ce00347457')
packObj compare ( 20102300000; 'cf00000004ae30c160')
packObj compare (4294967296;'cf0000000100000000')
packObj compare (_5; 'fb')
packObj compare (_3434;'d1f296')
packObj compare (_6544;'d1e670')
packObj compare (_214;'d1ff2a')
packObj compare (_87901;'d2fffea8a3')
packObj compare (_8845657000; 'd3fffffffdf0c1fc58')
packObj compare (_10000000; 'd2ff676980')
packObj compare (_6798; 'd1e572')
packObj compare (_4294967296;'d3ffffffff00000000')

NB. FLOAT TESTS
packObj compare ( 1.02; 'cb3ff051eb851eb852')
packObj compare ( _34.55656; 'cbc041473d5bab2181')
packObj compare ( 89744366.965; 'cb4195658fbbdc28f6')
packObj compare ( _0.0664333; 'cbbfb101c5d2dd8806')

NB. SINGLE DIMENSION INTEGER ARRAYS
packObj compare ((2 3 4 5); '9402030405')
packObj compare ((100 8589934592 6593); '9364cf0000000200000000cd19c1')

NB. ARRAY TEST
packObj compare ((3;(<'hi';6.3));'920392a26869cb4019333333333333') NB. equivalent to [3,["hi",6.3]]

NB. MULTIDIMENSIONAL ARRAYS
NB. 2x2x2 array of floats
packObj compare ((2 2 2 $ 2.1 4.3 6.7 8.888 1.1 0.9 1.001 3.14); '929292cb4000cccccccccccdcb401133333333333392cb401acccccccccccdcb4021c6a7ef9db22d9292cb3ff199999999999acb3feccccccccccccd92cb3ff004189374bc6acb40091eb851eb851f')
packObj compare ((<2 3 $ i.6); '929300010293030405')
packObj compare ((<2 3 $ <"0'abcdef');'9293a161a162a16393a164a165a166')
NB. STRINGS
packObj compare ('!>#$&+*'; 'a7213e2324262b2a')
packObj compare ('The quick brown fox...';'b654686520717569636b2062726f776e20666f782e2e2e')
packObj compare ('notation as a tool of thought!'; 'be6e6f746174696f6e206173206120746f6f6c206f662074686f7567687421')
NB. skip below test. It adds trailing elipsis. Needs fixing
NB. packObj testAdverb ( 'Lorem ipsum dolor sit amet, omnis quaeque vituperatoribus has te, atqui congue expetendis eu pri, denique liberavisse cu mel. Eripuit minimum an sit, at graece semper atomorum nam, ei disputando eloquentiam definitiones sit. Oratio latine comprehensam an quo. Ei usu partem putent equidem, an labitur saperet vivendum mea.';'da01424c6f72656d20697073756d20646f6c6f722073697420616d65742c206f6d6e69732071756165717565207669747570657261746f7269627573206861732074652c20617471756920636f6e677565206578706574656e646973206575207072692c2064656e69717565206c69626572617669737365206375206d656c2e')




NB. DICTIONARIES. NOTE: testing packed bytes using other implementations may have
NB. a different byte ordering due to differeing orders in hashmaps in different
NB. languages.
NB. 1. Test 3 key value pairs.
NB. JSON equivalent: {"key1":"value1","Key2":"value2","KEY3": "VALUE3"}
testQ =: '' conew 'HashMap'
set__testQ 'key1'; 'value1'
set__testQ 'Key2'; 'value2'
set__testQ 'KEY3'; 'VALUE3'
symTestQ =: s: testQ
packObj compare (symTestQ ; '83a46b657931a676616c756531a44b455933a656414c554533a44b657932a676616c756532')
NB. dictionary test 2
hm =: '' conew 'HashMap'
set__hm 'k2'; 50202
set__hm 'k1'; 3
set__hm 'k3'; i. 5
packObj compare ((s: hm) ; '83a26b32cdc41aa26b3103a26b33950001020304') NB. json = {"k2":50202, "k1":3, "k3":[0,1,2,3,4]}



NB. UNPACK tests
unpackObj compare ('02';2)
unpackObj compare ( 'ce00347457';3437655)
unpackObj compare ( 'ce00347457';3437655)
unpackObj compare ( '9acd0100cd0101cd0102cd0103cd0104cd0105cd0106cd0107cd0108cd0109';(<;/ (2^8)+i.10))
unpackObj compare ( '94050607ab736f6d6520737472696e67'; (<5;6;7;'some string'))





NB. JSON packing tests
packObjJSON compare ((i.5) ; '[0,1,2,3,4]')
packObjJSON compare (('cat';'dog';'elephant';'monkey';'octopus') ; '["cat","dog","elephant","monkey","octopus"]')
packObjJSON compare ((3.15 4.23 78.9544 _34.094); '[3.15,4.23,78.9544,-34.094]')
packObjJSON compare ((2 2 $ i.4); '[[0,1],[2,3]]')
packObjJSON compare ((s: testQ) ; '{"key1":"value1","KEY3":"VALUE3","Key2":"value2"}')
packObjJSON compare (('string';5.34;100) ; '["string",5.34,100]')