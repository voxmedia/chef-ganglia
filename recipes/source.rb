if platform?('redhat', 'centos', 'fedora')
  %w(apr-devel libconfuse-devel expat-devel rrdtool-devel).each do |p|
    package p
  end
elsif platform?('ubuntu', 'debian')
  %w(build-essential libconfuse-dev librrd-dev libexpat1-dev libapr1-dev python-dev).each do |p|
    package p
  end
end

remote_file "/usr/src/ganglia-#{node['ganglia']['version']}.tar.gz" do
  source node['ganglia']['uri']
  checksum node['ganglia']['checksum']
  action :create_if_missing
end

src_path = "/usr/src/ganglia-#{node['ganglia']['version']}"


execute 'install ganglia' do
  command 'make install'
  cwd src_path
  action :nothing
end

execute 'build ganglia' do
  command 'make'
  cwd src_path
  action :nothing
  notifies :run, 'execute[install ganglia]', :immediately
end

execute 'configure ganglia build' do
  command './configure --with-gmetad --with-libpcre=no --sysconfdir=/etc/ganglia --prefix=/usr'
  cwd src_path
  action :nothing
  notifies :run, 'execute[build ganglia]', :immediately
end

execute 'untar ganglia' do
  command "tar xzf ganglia-#{node['ganglia']['version']}.tar.gz"
  creates src_path
  cwd '/usr/src'
  notifies :run, 'execute[configure ganglia build]', :immediately
end

link '/usr/lib/ganglia' do
  to '/usr/lib64/ganglia'
  only_if do
    (node['kernel']['machine'] == 'x86_64') &&
      platform?('redhat', 'centos', 'fedora')
  end
end

directory '/usr/lib64/ganglia/python_modules' do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

directory '/etc/ganglia/conf.d' do
  owner 'root'
  group 'root'
  mode 0o0755
  action :create
end

cookbook_file '/etc/ganglia/conf.d/modpython.conf' do
  source 'modpython.conf'
  owner 'root'
  group 'root'
  mode 0o0644
end
