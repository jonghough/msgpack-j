# msgpack-j 
Implementation of the Message Pack serialization format in J. Can serialize J types, arrays and HashMap J objects into MsgPack compatible types and back again.

# Examples
# strings
`pack` packs J types into a byte string. `unpack` reverses this.

`pack 'hello world'`

`�hello world`

`unpack �hello world`

`'hello world'`

`packObj` packs J types into a hex string (string literal). `unpackObj` reverses this.

e.g.
`packObj 'Hello World'`

`ab48656c6c6f20576f726c64`

`unpackObj 'ab48656c6c6f20576f726c64'`

`Hello World`
#More Usage
Example:

`pack 2;4.67;'hello, world'`

`��@┐�┼z�G��hello, world`

`packObj 2;4.67;'hello, world'`

`9302cb4012ae147ae147aeac68656c6c6f2c20776f726c64`

JSON representation:
`[
  2,
  4.67,
  "hello, world"
]`


Example: 

`unpackObj '81a46461746183a2696401a673636f72657394cb400999999999999acb4016cccccccccccdcb40091eb851eb851fcb4007333333333333a56f7468657283a4736f6d65d1f2b8a46d6f7265ccc8a4646174610c'`
 returns a dictionary containing inner dictionaries.

JSON representation:

`{"data":{"id":1,"scores":[3.2,5.7,3.14,2.9],"other":{"some":_3400,"more":200,"data":12}}}`

#Handling dictionary / hashmap datatypes
Since J has no native Dictionary / Hashmap type, one has been implemented for the purposes of MsgPack serialization.

Construction:

`HM =: '' conew 'HashMap'`

This will instantiate a new HashMap object.

`set__HM 'key';'value'`

This will add a key value pair to the dicitonary. Note the length of the boxed array argument must be two. i.e. if  the value is an array itself, then it must be boxed together before appending to the key value.

`get__HM 'key'`

This will return the value for the given key, if one exists.

To pack a HashMap:

`packObj s: HM`

Here HM is the HashMap reference name. It must be symbolized first, before packing. Furthermore, to add a HashMap as a value of another HashMap:

`set__HM 'hashmapkey';s:HM2`

The inner HashMap reference (HM2) must be symbolized before adding to the dictionary. If you are adding a list of HashMaps to the parent HashMap:

`set__HM 'key'; <(s:HM2;s:HM3;s:HM4)`

Note the HashMap array is boxed so that the argument for `set` is of length two. Since the HashMap `HM` stores the reference to the child HashMaps as symbols, they must be desymbolized if retrieved. e.g.

`ChildHM =: getHashmapFromValue_HashMap_ get__HM 'mychildHashMapkey'`

Here, `getHashmapFromValue_HashMap_` ensures that the retrieved object is a reference to a hashmap, as is wanted.

When unpacking data, assuming the root object is a dictionary / hashmap:

`HM =: 5 s: unpackObj 'some serialized data'`

`5 s:` must be called to desymbolize the reference to the HashMap. Furthermore, all child HashMaps of `HM` must also be desymbolized too.



`
