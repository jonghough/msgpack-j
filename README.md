# msgpack-j 
Implementation of the Message Pack serialization format in J.
<h1>Usage</h1>
 import into projects and open in jqt or other. It's very simple. 
 
<h2>Examples</h2>
`pack` packs J types into a byte string. `unpack` reverses this.

<b>`pack 'hello world'`</b>

<b>`�hello world`</b>

<b>`unpack �hello world`</b>

<b>`'hello world'`</b>

`packObj` packs J types into a hex string (string literal). `unpackObj` reverses this.

e.g.
<b>`packObj 'Hello World'`</b>

<b>`ab48656c6c6f20576f726c64`</b>

<b>`unpackObj 'ab48656c6c6f20576f726c64'`</b>

<b>`Hello World`</b>
<h3>More Usage</h3>
Example:

<b>`pack 2;4.67;'hello, world'`</b>

<b>`��@┐�┼z�G��hello, world`</b>

<b>`packObj 2;4.67;'hello, world'`</b>

<b>`9302cb4012ae147ae147aeac68656c6c6f2c20776f726c64`</b>

JSON representation:
`[
  2,
  4.67,
  "hello, world"
]`


Example: 

<b>`unpackObj '81a46461746183a2696401a67
3636f72657394cb4009999999
99999acb4016cccccccccccdc
b40091eb851eb851fcb400733
3333333333a56f7468657283a
4736f6d65d1f2b8a46d6f7265
ccc8a4646174610c'`</b>

 returns a nested dictionary. 

JSON representation:

<b>`{"data":{"id":1,"scores":[3.2,5.7,3.14,2.9],"other":{"some":_3400,"more":200,"data":12}}}`</b>

<h3>Handling dictionary / hashmap datatypes</h3>

Since J has no native Dictionary / Hashmap type, one has been implemented for the purposes of MsgPack serialization.

Construction:

<b>`HM =: '' conew 'HashMap'`</b>

This will instantiate a new HashMap object.

<b>`set__HM 'key';'value'`</b>

This will add a key value pair to the dicitonary. Note the length of the boxed array argument must be two. i.e. if  the value is an array itself, then it must be boxed together before appending to the key value.

<b>`get__HM 'key'`</b>

This will return the value for the given key, if one exists.

To pack a HashMap:

<b>`packObj s: HM`</b>

Here HM is the HashMap reference name. It must be symbolized first, before packing. Furthermore, to add a HashMap as a value of another HashMap:

<b>`set__HM 'hashmapkey';s:HM2`</b>

The inner HashMap reference (HM2) must be symbolized before adding to the dictionary. If you are adding a list of HashMaps to the parent HashMap:

<b>`set__HM 'key'; <(s:HM2;s:HM3;s:HM4)`</b>

Note the HashMap array is boxed so that the argument for `set` is of length two. Since the HashMap `HM` stores the reference to the child HashMaps as symbols, they must be desymbolized if retrieved. e.g.

<b>`ChildHM =: getHashmapFromValue_HashMap_ get__HM 'mychildHashMapkey'`</b>

Here, <b>`getHashmapFromValue_HashMap_`</b> ensures that the retrieved object is a reference to a hashmap, as is wanted.

When unpacking data, assuming the root object is a dictionary / hashmap:

<b>`HM =: 5 s: unpackObj 'some serialized data'`</b>

<b>`5 s:`</b> must be called to desymbolize the reference to the HashMap. Furthermore, all child HashMaps of `HM` must also be desymbolized too.



`
