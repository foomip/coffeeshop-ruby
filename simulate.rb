libdir = "#{File.expand_path(File.dirname(__FILE__))}/lib"
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'coffeeshop'

Coffeeshop.open_for_business
