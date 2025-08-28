# frozen_string_literal: true

module Tests
  def test_dump_string
    assert_dump('<string>testdata</string>', 'testdata')
  end

  def test_dump_string_with_xml_encoding
    assert_dump('<string>&amp;</string>', '&')
  end

  def test_dump_binary_string
    assert_dump("<data>aGVsbG8=\n</data>", 'hello'.b)
  end

  def test_dump_string_with_other_encoding
    assert_dump('<string>你好</string>', '你好'.encode(Encoding::BIG5))
  end

  def test_dump_symbol
    assert_dump('<string>testdata</string>', :testdata)
  end

  def test_dump_strings_with_escaping
    assert_dump('<string>&lt;Fish &amp; Chips&gt;</string>', '<Fish & Chips>')
  end

  def test_dump_integer
    assert_dump('<integer>0</integer>', 0)
    assert_dump('<integer>1</integer>', 1)
    assert_dump('<integer>-1</integer>', -1)
    assert_dump('<integer>9527</integer>', 9527)
  end

  def test_dump_float
    assert_dump('<real>3.14</real>', 3.14)
    assert_dump('<real>1.23</real>', 1.23)
  end

  def test_dump_boolean
    assert_dump('<true/>', true)
    assert_dump('<false/>', false)
  end

  def test_dump_time
    assert_dump(
      '<date>1989-11-23T11:23:24Z</date>',
      Time.utc(1989, 11, 23, 11, 23, 24)
    )
    assert_dump(
      '<date>1989-11-23T03:23:24Z</date>',
      Time.new(1989, 11, 23, 11, 23, 24, '+08:00')
    )
  end

  def test_dump_date
    assert_output(nil, /consider/i) do
      assert_dump(
        '<date>1995-01-10T00:00:00Z</date>',
        Date.new(1995, 1, 10)
      )
    end
  end

  def test_dump_datetime
    assert_dump(
      '<date>1989-11-23T11:23:05Z</date>',
      DateTime.new(1989, 11, 23, 11, 23, 5)
    )
    assert_dump(
      '<date>1989-11-23T03:23:05Z</date>',
      DateTime.new(1989, 11, 23, 11, 23, 5, 8/24r)
    )
  end

  def test_dump_array
    assert_dump(
      '<array><integer>1</integer><integer>2</integer></array>',
      [1, 2]
    )
  end

  def test_dump_hash
    assert_dump(
      '<dict><key>foo</key><string>bar</string></dict>',
      { foo: :bar }
    )
  end

  def test_dump_hash_with_non_string_keys
    assert_dump(
      '<dict><key>[1, 2, 3]</key><integer>2</integer></dict>',
      { [1, 2, 3] => 2 }
    )
  end

  def test_dump_hash_with_reserved_character
    assert_dump(
      '<dict><key>&amp;</key><integer>2</integer></dict>',
      { '&' => 2 }
    )
  end

  def test_dump_nested_objects
    assert_dump(
      '<dict><key>foo</key><array><integer>1</integer><integer>2</integer></array></dict>',
      { foo: [1, 2] }
    )
  end

  def test_load_integer
    assert_load 1, '<integer>1</integer>'
    assert_load 9527, '<integer>9527</integer>'
    assert_load(-1, '<integer>-1</integer>')
  end

  def test_load_real
    assert_load 3.14, '<real>3.14</real>'
    assert_load 2E+2, '<real>2E+2</real>'
    assert_load(-3.14, '<real>-3.14</real>')
  end

  def test_load_boolean
    assert_load true, '<true/>'
    assert_load false, '<false/>'
  end

  def test_load_date
    assert_load Time.utc(2020, 11, 23, 11, 23, 24), '<date>2020-11-23T11:23:24Z</date>'
  end

  def test_load_string
    assert_load 'test', '<string>test</string>'
    assert_load %q(&<>"'), %q(<string>&amp;&lt;&gt;"'</string>)
    assert_load %q("'), '<string>&quot;&apos;</string>'
  end

  def test_load_data
    assert_load "hello\nworld\n", '<data>aGVsbG8Kd29ybGQK</data>'
  end

  def test_load_array
    assert_load [1, 2], '<array><integer>1</integer><integer>2</integer></array>'
  end

  def test_load_hash
    assert_load(
      { 'foo' => 'bar' },
      '<dict><key>foo</key><string>bar</string></dict>'
    )
  end

  def test_load_nested_objects
    assert_load(
      { 'foo' => [1, 2] },
      '<dict><key>foo</key><array><integer>1</integer><integer>2</integer></array></dict>'
    )
  end

  def test_load_encoding
    assert_equal(
      '僕は新世界の神となる',
      PlistLite.load(<<~PLIST)
        <?xml version="1.0" encoding="EUC-JP"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
          <string>#{'僕は新世界の神となる'.encode(Encoding::EUC_JP)}</string>
        </plist>
      PLIST
    )
  end

  def test_raise_error_when_load_empty_file
    assert_raises Nokogiri::XML::SyntaxError do
      PlistLite.load('')
    end
  end

  def test_raise_error_when_load_witout_dtd
    assert_raises Nokogiri::XML::SyntaxError do
      PlistLite.load('<?xml version="1.0"?><_/>')
    end
  end

  def test_identical
    obj = { 'foo' => 'foo', 'bar' => [1, { 'buz' => 'buz' }] }
    assert_equal(
      obj,
      PlistLite.load(PlistLite.dump(obj))
    )
  end

  def test_dump_raises_argument_error_for_unsupported_type
    assert_raises ArgumentError do
      PlistLite.dump(Object.new)
    end
  end

  private

  def assert_load(expected, content)
    assert_equal expected, PlistLite.load(wrap(content))
  end

  def assert_dump(expected, object)
    assert_equal wrap(expected), PlistLite.dump(object)
  end

  def wrap(content)
    '<?xml version="1.0" encoding="UTF-8"?>' \
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
    "<plist version=\"1.0\">#{content}</plist>"
  end
end
