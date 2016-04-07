NB. Some tests for the MsgPack implementation.
NB. The correct results were taken from MsgPack.org
NB. http://msgpack-json-editor.com and testing with Javascript
NB. implementation of MsgPack.

require '~user/projects/MsgPack/msgpack-j/msgpack.ijs'
require '~user/projects/MsgPack/msgpack-j//hashmap.ijs'

NB. compare adverb.
NB. 0{n is the argument, u is the verb to be tested,
NB. 1{n is the expected result (boxed)
compare =: 2 : '((u&.>)0{n) -: (1{n)'
match =: 2 : '((u&.>)0{n) -: (((_1&*@<: @#) {. ])n)'

NB. INTEGERS TESTS
pack_obj compare ( 0; '00')
pack_obj compare ( 2; '02')
pack_obj compare ( 34; '22')
pack_obj compare ( 128; 'cc80')
pack_obj compare ( _128; 'd1ff80')
pack_obj compare ( 65536; 'ce00010000')
pack_obj compare ( _65536; 'd2ffff0000')
pack_obj compare ( 3437655; 'ce00347457')
pack_obj compare ( 20102300000; 'cf00000004ae30c160')
pack_obj compare ( 4294967296;'cf0000000100000000')
pack_obj compare (_5; 'fb')
pack_obj compare (_3434;'d1f296')
pack_obj compare (_6544;'d1e670')
pack_obj compare (_214;'d1ff2a')
pack_obj compare (_87901;'d2fffea8a3')
pack_obj compare (_8845657000; 'd3fffffffdf0c1fc58')
pack_obj compare (_10000000; 'd2ff676980')
pack_obj compare (_6798; 'd1e572')
pack_obj compare (_4294967296;'d3ffffffff00000000')

NB. FLOAT TESTS
pack_obj compare ( 1.02; 'cb3ff051eb851eb852')
pack_obj compare ( _34.55656; 'cbc041473d5bab2181')
pack_obj compare ( 89744366.965; 'cb4195658fbbdc28f6')
pack_obj compare ( _0.0664333; 'cbbfb101c5d2dd8806')
pack_obj compare (1000.0102; 'cb408f4014e3bcd35b')
pack_obj compare (0.00123; 'cb3f5426fe718a86d7')

NB. SINGLE DIMENSION INTEGER ARRAYS
pack_obj compare ((2 3 4 5); '9402030405')
pack_obj compare ((100 8589934592 6593); '9364cf0000000200000000cd19c1')

NB. FLOAT ARRAYS
pack_obj compare ((0.1 0.2 0.3 0.4); '94cb3fb999999999999acb3fc999999999999acb3fd3333333333333cb3fd999999999999a')
pack_obj compare ((5.12 4.89 10.773 10000.24); '94cb40147ae147ae147bcb40138f5c28f5c28fcb40258bc6a7ef9db2cb40c3881eb851eb85')
pack_obj compare ((200.11 392 4949.303 7.9999); '94cb406903851eb851eccd0188cb40b3554d916872b0cb401fffe5c91d14e4')



NB. ARRAY TEST
pack_obj compare ((3;(<'hi';6.3));'920392a26869cb4019333333333333') NB. equivalent to [3,["hi",6.3]]

NB. MULTIDIMENSIONAL ARRAYS
NB. 2x2x2 array of floats
pack_obj compare ((2 2 2 $ 2.1 4.3 6.7 8.888 1.1 0.9 1.001 3.14); '929292cb4000cccccccccccdcb401133333333333392cb401acccccccccccdcb4021c6a7ef9db22d9292cb3ff199999999999acb3feccccccccccccd92cb3ff004189374bc6acb40091eb851eb851f')
pack_obj compare ((<2 3 $ i.6); '929300010293030405')
pack_obj compare ((<2 3 $ <"0'abcdef');'9293a161a162a16393a164a165a166')
NB. STRINGS
pack_obj compare ('!>#$&+*'; 'a7213e2324262b2a')
pack_obj compare ('The quick brown fox...';'b654686520717569636b2062726f776e20666f782e2e2e')
pack_obj compare ('notation as a tool of thought!'; 'be6e6f746174696f6e206173206120746f6f6c206f662074686f7567687421')
pack_obj compare ('おはようございます'; 'bbe3818ae381afe38288e38186e38194e38196e38184e381bee38199')


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
pack_obj compare (symTestQ ; '83a46b657931a676616c756531a44b455933a656414c554533a44b657932a676616c756532')



NB. UNPACK tests
unpack_obj compare ('02';2)
unpack_obj compare ('00';0)
unpack_obj compare ('ce00347457';3437655)
unpack_obj compare ('cb40f8024654562e0a';98340.39559)
unpack_obj compare ('ba74686520717569636b2062726f776e20666f78206a756d706564';'the quick brown fox jumped')
unpack_obj compare ('9acd0100cd0101cd0102cd0103cd0104cd0105cd0106cd0107cd0108cd0109';(<;/ (2^8)+i.10))
unpack_obj compare ('94050607ab736f6d6520737472696e67'; (<5;6;7;'some string'))


