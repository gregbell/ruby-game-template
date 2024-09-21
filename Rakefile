require 'webrick'

task :server do
  root = File.expand_path('.')

  server = WEBrick::HTTPServer.new(
    Port: 8000,
    DocumentRoot: root
  )

  trap('INT') { server.shutdown } # Ctrl-C to stop

  server.start
end
