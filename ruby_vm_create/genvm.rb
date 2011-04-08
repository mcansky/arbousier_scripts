# the tool to create VMs
require "rubygems" # ruby1.9 doesn't "require" it though
require "thor"

class JesterSmith < Thor
  include Thor::Actions

  def dummy?(config)
    return true if config.dummy == 1
    return false
  end

  argument :name, :version, :ip, :storage

  # loading some vars
  config = YAML::parse( File.open( "config.yml" ) )
  tools = ["lvcreate","mkfs","mount","debootstrap","mkdir","cat","dd","mkswap","echo"]
  n_name = name.gsub(/\s/, '_')
  name = name.downcase
  version = version.downcase
  for_line = "for #{name} on #{storage}"
  if dummy?(config)
    config.build_dir = "/tmp/jester"
  end

  # creating dirs
  FileUtils.mkdir_p(config.log_dir)
  FileUtils.mkdir_p(config.build_dir)

  # creating the fs
  say "Creating filesystem #{for_line}", :green
  run("lvcreate -L#{config.lv_size} -n #{n_name} -n #{storage}")
  # creating the swap
  say "Creating swap #{for_line}", :green
  run("lvcreate -L#{config.lv_swap_size} -n swap_#{n_name} -n #{storage}")
  # making the fs
  say "Mkfs filesystem #{for_line}", :green
  run("mkfs -t ext4 /dev/#{storage}/#{n_name}")
  # mkfs swap
  say "Mkfs swap #{for_line}", :green
  run("mkswap /dev/#{storage}/swap_#{n_name}")
  # mount new fs
  say "Mounting #{name} fs in build dir", :green
  run("mount /dev/#{storage}/#{n_name} #{config.build_dir}")

  # debootstrap
  raise ArgumentError, "version not known"
  # default args aka squeeze 64
  arch = "amd64"
  kernel = "linux-image-2.6-amd64"
  base = "squeeze"
  case
    when version == "lenny"
      arch = "amd64"
      kernel = "linux-image-2.6-xen-amd64"
      base = "lenny"
    when version == "squeeze32"
      arch = "i386"
      kernel = "linux-image-2.6-686-bigmem"
      base = "squeeze"
    when version == "squeeze64"
      arch = "amd64"
      kernel = "linux-image-2.6-amd64"
      base = "squeeze"
  end
  # running the debootstrap
  say "Deboostraping #{name} as #{version}", :green
  run("debootstrap --arch=#{arch} --components=main,contrib,non-free --include=#{kernel} #{base} #{config.build_dir} #{config.mirror}")

  # creating storage for kernels
  say "Creating kernel storage for #{name}", :green
  FileUtils.mkdir_p("/home/xen/domu/#{name}/kernel")

  # copying kernel files
  say "Copying kernel and initrd for #{name}", :green
  copy_file("#{config.build_dir}/vmlinuz-*", "/home/xen/domu/#{name}/kernel/")
  copy_file("#{config.build_dir}/initrd-*", "/home/xen/domu/#{name}/kernel/")
  # storing the names
  vmlinuz_file = Dir.glob("/home/xen/domu/#{name}/kernel/vmlinuz-*").first
  initrd_file = Dir.glob("/home/xen/domu/#{name}/kernel/initrd-*").first

  # generating xen config file
  xenconf = <<-EOF
    kernel = #{vmlinuz_file}
    ramdisk= #{initrd_file}
    memory = 512
    name = '#{name}'
    vif = [ 'ip=#{ip}' ]
    disk = [
        'phy:/dev/zor0/#{name},xvda1,w',
        'phy:/dev/zor0/swap_#{name},xvda2,w'
    ]
    root = '/dev/xvda1 ro'
    console = 'hvc0'
  EOF
  # removing white chars at start of lines
  xenconf.gsub!(/^\s*/,'')
  # creating the config file
  say "Creating xenconf file for #{name}", :green
  create_file "/etc/xen/xen.d/#{name}.cfg", xenconf

  # generating network config file
  network_conf = <<-EOF
  interfaces="auto lo
  iface lo inet loopback
  
  auto eth0
  iface eth0 inet static
          address #{IP}
          gateway #{config.gateway}
          netmask 255.255.255.0"
  EOF
  network_conf.gsub!(/^\s*/,'')
  # creating the config file
  say "Creating network file for #{name}", :green
  create_file "#{conf.build_dir}/etc/network/interfaces", network_conf

  # creating the fstab file
  fstab_file = <<-EOF
    /dev/xvda1      /                   ext3        defaults        0       1
    /dev/xvda2      none                swap        defaults        0       0
    proc            /proc               proc        defaults        0       0
  EOF
  fstab_file.gsub(/^\s*/,'')
  # creating the fstab file
  say "Creating fstab file for #{name}", :green
  create_file "#{conf.build_dir}/etc/fstab", fstab_file

  # adding line to inittab
  say "Adding hvc0 line to inittab for #{name}", :green
  prepend_to_file "#{conf.build_dir}/etc/inittab", "hvc0:23:respawn:/sbin/getty 38400 hvc0"

  # hostname
  say "Creating hostname file for #{name}", :green
  create_file "#{conf.build_dir}/etc/hostname", name

  # sources for apt
  apt_sources = <<-EOF
    sources="deb http://mir1.ovh.net/debian/ #{base} main contrib non-free
    deb-src http://mir1.ovh.net/debian/ #{base} main contrib non-free

    deb http://security.debian.org/ #{base}/updates main
    deb-src http://security.debian.org/ #{base}/updates main
  EOF
  apt_sources.gsub(/^\s*/,'')
  say "Adding apt-sources for #{name}", :green
  create_file "#{conf.build_dir}/etc/apt/sources.list", apt_sources

  # DONE
end
JesterSmith.start