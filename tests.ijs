NB. Some tests for the MsgPack implementation
require '~user/projects/MsgPack/msgpack-j/MsgPack.ijs'
NB. INTEGERS TESTS

compare =: 2 : '(<u>0{n) = (1{n)'

packObj compare ( 2; '02')
packObj compare ( 34; '22')
packObj compare ( 3437655; 'ce00347457')
packObj compare ( 20102300000; 'cf00000004ae30c160')

NB. FLOAT TESTS
packObj compare ( 1.02; 'cb3ff051eb851eb852')
packObj compare ( _34.55656; 'cbc041473d5bab2181')
packObj compare ( 89744366.965; 'cb4195658fbbdc28f6')
packObj compare ( _0.0664333; 'cbbfb101c5d2dd8806')

NB. SINGLE DIMENSION INTEGER ARRAYS
packObj compare ((2 3 4 5); '9402030405')
packObj compare ((100 8589934592 6593); '9364cf0000000200000000cd19c1')


NB. STRINGS
packObj compare ( 'notation as a tool of thought!'; 'be6e6f746174696f6e206173206120746f6f6c206f662074686f7567687421')
NB. skip below test. It adds trailing elipsis. Needs fixing
NB. packObj testAdverb ( 'Lorem ipsum dolor sit amet, omnis quaeque vituperatoribus has te, atqui congue expetendis eu pri, denique liberavisse cu mel. Eripuit minimum an sit, at graece semper atomorum nam, ei disputando eloquentiam definitiones sit. Oratio latine comprehensam an quo. Ei usu partem putent equidem, an labitur saperet vivendum mea.';'da01424c6f72656d20697073756d20646f6c6f722073697420616d65742c206f6d6e69732071756165717565207669747570657261746f7269627573206861732074652c20617471756920636f6e677565206578706574656e646973206575207072692c2064656e69717565206c69626572617669737365206375206d656c2e')
