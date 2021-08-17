
require 'yaml'
yaml = YAML.load_file('../manifest.yml')
name = yaml["NAME"]
name2 = name.sub('MBox', 'mbox').underscore
version = ENV["VERSION"] || yaml["VERSION"]

Pod::Spec.new do |spec|
  spec.name         = "#{name}"
  spec.version      = "#{version}"
  spec.summary      = "Workspace Plugin for MBox."
  spec.description  = <<-DESC
    Manage repos and features.
                   DESC

  spec.homepage     = "https://github.com/MBoxPlus/#{name2}"

  spec.license      = "MIT"
  spec.author       = { `git config user.name`.strip => `git config user.email`.strip }
  spec.source       = { :git => "git@github.com:MBoxPlus/#{name2}.git", :tag => "#{spec.version}" }
  spec.platform     = :osx, '10.15'

  spec.default_subspec = 'Default'

  spec.subspec 'Core' do |ss|
    ss.source_files = "#{name}/MBWorkspaceCore/*.{h,m,swift}", "#{name}/MBWorkspaceCore/**/*.{h,m,swift}"
    ss.dependency "MBoxCore"
    ss.dependency "MBoxGit"
  end
  spec.subspec 'Loader' do |ss|
    ss.source_files = "#{name}/MBWorkspaceLoader/*.{h,m,swift}", "#{name}/MBWorkspaceLoader/**/*.{h,m,swift}"

    yaml['NATIVE_DEPENDENCIES']['Loader'].each do |name|
      ss.dependency name
    end
  end
  spec.subspec 'Default' do |ss|
    ss.source_files = "#{name}/MBWorkspace/*.{h,m,swift}", "#{name}/MBWorkspace/**/*.{h,m,swift}"

    yaml['DEPENDENCIES']&.each do |name|
      ss.dependency name
    end
    yaml['FORWARD_DEPENDENCIES']&.each do |name, _|
      ss.dependency name
    end
    ss.dependency "MBoxWorkspace/Loader"
  end
end
