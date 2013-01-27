#!/usr/bin/env ruby
 
require 'rubygems'
require 'colored'
require 'pathname'
require 'fileutils'

product_name     = 'libPusher'
test_bundle_name = 'UnitTests'

source_root        = File.expand_path('../..', __FILE__)
derived_data_root  = File.join(source_root, 'DerivedData')
built_products_dir = File.join(derived_data_root, product_name, 'Build/Products/Debug-iphonesimulator')
dev_root           = '/Applications/Xcode.app/Contents/Developer'
# TODO Make this dynamic
sdk_root           = File.join(dev_root, 'Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk')
 
ENV['DYLD_FRAMEWORK_PATH']           = "#{built_products_dir}:#{File.join(sdk_root, 'Applications/Xcode.app/Contents/Developer/Library/Frameworks')}"
ENV['DYLD_LIBRARY_PATH']             = built_products_dir
ENV['DYLD_NEW_LOCAL_SHARED_REGIONS'] = 'YES'
ENV['DYLD_NO_FIX_PREBINDING']        = 'YES'
ENV['DYLD_ROOT_PATH']                = sdk_root
ENV['IPHONE_SIMULATOR_ROOT']         = sdk_root
ENV['CFFIXED_USER_HOME']             = File.expand_path('~/Library/Application Support/iPhone Simulator/')

FileUtils.mkdir_p(ENV['CFFIXED_USER_HOME'])
puts `ls -l #{derived_data_root}`

@verbose = !!ARGV.delete('--verbose')
test_suites = ARGV.empty? ? 'All' : ARGV.uniq.join(',')
 
command = "#{File.join(sdk_root, 'Developer/usr/bin/otest')} -SenTest #{test_suites} #{File.join(built_products_dir, "#{test_bundle_name}.octest")} 2>&1"

puts command

def handle_output(line)
  return if !@verbose && line =~ /^Test (Case|Suite)/
  case line
  when /\[PASSED\]/
    line.green
  when /\[PENDING\]/
    line.yellow
  when /^(.+?\.m)(:\d+:\s.+?\[FAILED\].+)/m
    # shorten the path to the test file to be relative to the source root
    if $1 == 'Unknown.m'
      line.red
    else
      (Pathname.new($1).relative_path_from(@source_root).to_s + $2).red
    end
  else
    line
  end
end

IO.popen(command) do |io|
  begin
    while line = io.readline
      if output = handle_output(line)
        $stdout.puts output
      end
    end
  rescue EOFError
  end
end

exit $?.exitstatus
