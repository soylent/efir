# frozen_string_literal: true

require 'open3'
require 'pathname'
require 'tempfile'

contracts = Pathname(__dir__).join('contracts')

def assert_bin_efir(
  opts: ['--test'], stdin: nil, stdout: nil, stderr: nil, success: true
)
  out, err, status = Open3.capture3('bin/efir', *opts, stdin_data: stdin)

  stderr_ok = stderr ? err.include?(stderr) : err.empty?
  assert stderr_ok, "stderr: #{err}"

  stdout_ok = stdout ? out.match?(stdout) : out.empty?
  assert stdout_ok, "stdout: #{out}"

  assert_equal success, status.success?
end

test 'that it checks options' do
  assert_bin_efir(opts: [], stderr: 'Usage:', success: false)
  assert_bin_efir(opts: ['--oifu'], stderr: 'invalid option', success: false)
  assert_bin_efir(opts: ['--env'], stderr: 'missing argument', success: false)
  assert_bin_efir(opts: ['--deploy'], stderr: 'Usage:', success: false)
  assert_bin_efir(opts: ['--deploy', ''], stderr: 'Usage:', success: false)
  assert_bin_efir(opts: ['--deploy', 'x', '--test'], stderr: 'Usage:', success: false)
end

test 'that it handles invalid json input' do
  error_msg = 'cannot parse input: "x"'
  assert_bin_efir(stdin: 'x', stderr: error_msg, success: false)

  error_msg = 'cannot parse input: "xxxxxxxxxxxxxxxx..."'
  assert_bin_efir(stdin: 'x' * 17, stderr: error_msg, success: false)
end

test 'that it prints nothing if the input is empty' do
  assert_bin_efir(stdin: '', stdout: /\A\z/)
end

test 'that it reports passing tests' do
  contract = contracts.join('TestSuccess.json')

  assert_bin_efir(stdin: contract.read, stdout: /\A\.\n\z/)
end

test 'that it reports failing tests' do
  contract = contracts.join('TestFailure.json')

  stdout = /\AF\nF: TestFailure\.sol:TestFailure:testFailure\(\): expected failure/
  assert_bin_efir(stdin: contract.read, stdout: stdout, success: false)
end

test 'that it reports test errors' do
  contract = contracts.join('TestErrors.json')

  assert_bin_efir(stdin: contract.read, stdout: /\AEE/, success: false)
end

test 'that it prints nothing if there are no tests' do
  contract = contracts.join('Example.json')

  assert_bin_efir(stdin: contract.read)
end

test 'that it warns about ignored test functions' do
  contract = contracts.join('TestWarning.json')

  assert_bin_efir(stdin: contract.read, stderr: 'ignored')
end

test 'that it tests files provided as arguments' do
  file = contracts.join('TestSuccess.json').to_s

  assert_bin_efir(opts: ['--test', file, file], stdout: /\A\.\.\n\z/)
end

test 'that it handles unreadable files' do
  Tempfile.create do |file|
    file.chmod(0)

    opts = ['--test', file.path]
    assert_bin_efir(opts: opts, stderr: 'cannot read', success: false)
  end
end

test 'that it can deploy a contract' do
  contract = contracts.join('Example.json')

  opts = ['--deploy', 'Example']
  stdout = /"address":"0x[0-9A-z]{40}","abi":/
  assert_bin_efir(opts: opts, stdin: contract.read, stdout: stdout)
end

test 'that it fails if the contract is not found' do
  contract = contracts.join('Example.json')

  opts = ['--deploy', 'x']
  assert_bin_efir(opts: opts, stdin: contract.read, stderr: 'not found', success: false)
end

test 'that it shows help' do
  assert_bin_efir(opts: ['--help'], stdout: 'Usage:')
end

test 'that it shows version' do
  assert_bin_efir(opts: ['--version'], stdout: /\A\d+\.\d+\.\d+/)
end
