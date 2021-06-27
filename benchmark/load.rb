# frozen_string_literal: true

require 'benchmark'
require 'plist'
require 'plist_lite'

source = DATA.read

n = 10_000
Benchmark.bmbm do |bench|
  bench.report('Plist.parse_xml') { n.times { Plist.parse_xml(source) } }
  bench.report('PlistLite.load') { n.times { PlistLite.load(source) } }
end

__END__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>FirstName</key>
    <string>John</string>
    <key>LastName</key>
    <string>Public</string>
    <key>StreetAddr1</key>
    <string>123 Anywhere St.</string>
    <key>StateProv</key>
    <string>CA</string>
    <key>City</key>
    <string>Some Town</string>
    <key>CountryName</key>
    <string>United States</string>
    <key>AreaCode</key>
    <string>555</string>
    <key>LocalPhoneNumber</key>
    <string>5551212</string>
    <key>ZipPostal</key>
    <string>12345</string>
  </dict>
</plist>
