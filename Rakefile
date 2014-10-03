require 'rake/testtask'

desc 'Runs tests'
Rake::TestTask.new do |task|
  task.libs << 'test'
  task.test_files = FileList['test/test*.rb']
end
