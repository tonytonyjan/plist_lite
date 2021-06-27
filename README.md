![](https://github.com/tonytonyjan/plist_lite/actions/workflows/test.yml/badge.svg)

# plist_lite

`plist_lite` the fastest plist processor for Ruby written in C.

It can convert Ruby object to XML [plist (a.k.a. property list)](https://en.wikipedia.org/wiki/Property_list#macOS), vice versa.

## Usage

`plist_lite` does one thing and does it well.
It only has 2 API:

- `PlistLite#dump(object)`
- `PlistLite#load(plist_string)`

```ruby
require 'plist_lite'
plist = PlistLite.dump({foo: 'bar', ary: [1,2,3], time: Time.at(0)})
# => "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>foo</key><string>bar</string><key>ary</key><array><integer>1</integer><integer>2</integer><integer>3</integer></array><key>time</key><date>1970-01-01T00:00:00Z</date></dict></plist>"
PlistLite.load(plist)
# => {"foo"=>"bar", "ary"=>[1, 2, 3], "time"=>1970-01-01 00:00:00 UTC}
```

### Supported Types

- `Array` - `<array>`
- `Hash` - `<dict>`
- `Integer` - `<integer>`
- `Float` - `<real>`
- `TrueClass` - `<true/>`
- `FalseClass` - `<falst/>`
- `String`
  - binary encoding - `<data>`
  - other encodings - `<string>`
- `Symbol` - `<string>`
- `Time` - `<date>`
- `DateTime` - `<date>`
- `Date` - `<date>`
  - avoid using this because it does not have time zone information like `Time` or `DateTime`.

## Why plist_lite?

There is another competitor called [plist](https://github.com/patsplat/plist).

I am not a big fan of reinventing wheels, but when I see all the other wheels are square-shaped, they leave me no choice.

Here are some reasons of why `plist_lite` is better than `plist`.

1. `plist_lite` is 5 times faster than `plist`, see [benchmark](#benchmark).
2. `plist_lite` knows how to handle encoding while `plist` doesn't.

   <details>

   `plist` assume all strings are UTF-8 encoded.

   ```shell
   ruby -rplist -e 'puts Plist::Emit.dump("兜".encode(Encoding::BIG5))'
   ```

   ```
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <string></string>
   </plist>
   ```

   </details>

3. `plist_lite` treat binary string as binary data while `plist` treats `IO` and `StringIO` instances as binary data. The design of `plist` makes little sense.
4. `plist` uses `Marshal#dump` to handle unsupported data types that makes it vulnerable.
5. `plist_lite` knows how to handle XML encoding while `plist` doesn't.

   <details>

   According the [the spec](https://www.w3.org/TR/xml/), escaping `"` and `'` is unnecessary.

   ```shell
   ruby -rplist -e 'puts Plist::Emit.dump "\""'
   ```

   ```
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <string>&quot;</string>
   </plist>
   ```

   </details>

## Benchmark

```shell
ruby -Ilib benchmark/dump.rb
```

```
Rehearsal ----------------------------------------------------
Plist::Emit.dump   3.715427   0.003159   3.718586 (  3.720294)
PlistLite.dump     0.634391   0.000851   0.635242 (  0.635718)
------------------------------------------- total: 4.353828sec

                       user     system      total        real
Plist::Emit.dump   3.853843   0.003882   3.857725 (  3.860390)
PlistLite.dump     0.700628   0.001118   0.701746 (  0.702823)
```

```sh
ruby -Ilib benchmark/load.rb
```

```
Rehearsal ---------------------------------------------------
Plist.parse_xml   2.220934   1.423194   3.644128 (  3.645330)
PlistLite.load    0.598344   0.007032   0.605376 (  0.605603)
------------------------------------------ total: 4.249504sec

                      user     system      total        real
Plist.parse_xml   2.265274   1.454423   3.719697 (  3.721122)
PlistLite.load    0.673733   0.005373   0.679106 (  0.679638)
```
