## /* vim: set ft=ruby tabstop=4 softtabstop=4 shiftwidth=4 expandtab smarttab autoindent: */

Vagrant.require_version '>= 1.9.3'

# VM settings
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1

# Chrome installation script
$chrome_script = <<-'SCRIPT'
bash "/tmp/chrome/install-chrome.sh"
rm -rf "/tmp/chrome"
SCRIPT

Vagrant.configure('2') do |config|
    # Generic settings
    # Box
    config.vm.box = 'bento/debian-10.4'

    # Virtualbox
    config.vm.provider 'virtualbox' do |vb|
        vb.gui = $vm_gui
        vb.memory = $vm_memory
        vb.cpus = $vm_cpus
        vb.customize ['modifyvm', :id, '--usb', 'off']
        vb.customize ['modifyvm', :id, '--usbehci', 'off']
    end

    # SSH settings
    config.ssh.forward_agent = true

    # The robot server
    config.vm.define :'robot' do |db_master|
        # Hostname
        db_master.vm.hostname = 'robot'
        
        # Network settings
        db_master.vm.network 'private_network', ip: '192.168.33.61'
    end

    # Set up the file sync
    config.vm.synced_folder "reports/", "/mnt/reports"

    # Provision with Ansible
    config.vm.provision 'ansible' do |ansible|
        ansible.compatibility_mode = '2.0'
        ansible.playbook = 'install.yml'

        ansible.host_vars = {
            'robot' => {
                'nodm_user' => 'vagrant'
            }
        }
    end

    # Copy the Chrome installer
    config.vm.provision 'file', source: 'chrome', destination: '/tmp/chrome'

    # Install the Chrome
    config.vm.provision 'shell', inline: $chrome_script

    # Copy the Robot jobs
    config.vm.provision 'file', source: 'robot', destination: '/home/vagrant/robot'
end
