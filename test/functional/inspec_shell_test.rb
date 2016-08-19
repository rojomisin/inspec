# encoding: utf-8

require 'functional/helper'

describe 'inspec shell tests' do
  include FunctionalHelper

  describe 'cmd' do
    it 'can run ruby expressions' do
      x = rand
      y = rand
      out = inspec("shell -c '#{x} + #{y}' --format 'json'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      j = JSON.load(out.stdout)
      j.must_equal x+y

      out = inspec("shell -c '#{x} + #{y}'")
      out.exit_status.must_equal 0
      out.stdout.must_equal "#{x+y}\n"
    end

    it 'can run arbitrary ruby' do
      out = inspec("shell -c 'x = [1,2,3].inject(0) {|a,v| a + v*v}; x+10' --format 'json'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      j = JSON.load(out.stdout)
      j.must_equal 24  # 1^2 + 2^2 + 3^2 + 10

      out = inspec("shell -c 'x = [1,2,3].inject(0) {|a,v| a + v*v}; x+10'")
      out.exit_status.must_equal 0
      out.stdout.must_equal "24\n"
    end

    it 'retrieves resources in JSON' do
      out = inspec("shell -c 'os.params' --format 'json'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      j = JSON.load(out.stdout)
      j.keys.must_include 'name'
      j.keys.must_include 'family'
      j.keys.must_include 'arch'
      j.keys.must_include 'release'

      out = inspec("shell -c 'os.params'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      out.stdout.must_include 'name'
      out.stdout.must_include 'family'
      out.stdout.must_include 'arch'
      out.stdout.must_include 'release'
    end

    it 'runs anonymous tests' do
      out = inspec("shell -c 'describe file(\"#{__FILE__}\") do it { should exist } end' --format 'json'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      j = JSON.load(out.stdout)
      j.keys.must_include 'version'
      j.keys.must_include 'profiles'
      j.keys.must_include 'other_checks'
      j.keys.must_include 'summary'
      j['summary']['example_count'].must_equal 1
      j['summary']['failure_count'].must_equal 0

      out = inspec("shell -c 'describe file(\"#{__FILE__}\") do it { should exist } end'")
      out.stderr.must_equal ''
      out.exit_status.must_equal 0
      out.stdout.must_include '1 successful'
      out.stdout.must_include '0 failures'
    end
  end

  describe 'shell' do
    it 'provides a help command' do
      out = CMD.run_command("echo \"help\nexit\" | #{exec_inspec} shell")
      out.exit_status.must_equal 0
      out.stdout.must_include 'Available commands:'
      out.stdout.must_include 'You are currently running on:'
    end

    it 'exposes all resources' do
      out = CMD.run_command("echo \"os\nexit\" | #{exec_inspec} shell")
      out.exit_status.must_equal 0
      out.stdout.must_match /\=> .*Operating.* .*System.* .*Detection/
    end
  end
end
