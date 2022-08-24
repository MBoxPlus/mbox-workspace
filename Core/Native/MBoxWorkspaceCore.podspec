require 'yaml'

Pod::Spec.new do |spec|
  package_root = spec.class.mb_find_plugin_package_root(".")
  package_yaml = YAML.load_file(File.join(package_root, 'manifest.yml'))
  version = ENV["VERSION"] || package_yaml["VERSION"]
  package_name = package_yaml["NAME"]

  root = spec.class.mb_find_plugin_module_root(".")
  yaml = YAML.load_file(File.join(root, 'manifest.yml'))
  module_name = yaml["NAME"]

  spec.name         = "#{module_name}"
  spec.version      = "#{version}"
  spec.summary      = "Workspace Plugin for MBox."
  spec.description  = <<-DESC
    Manage repos and features.
                   DESC

  spec.homepage     = "https://github.com/MBoxPlus/#{package_name}"

  spec.license      = "MIT"
  spec.author       = { `git config user.name`.strip => `git config user.email`.strip }
  spec.source       = { :git => "git@github.com:MBoxPlus/mbox-workspace.git", :tag => "#{spec.version}" }
  spec.platform     = :osx, '10.15'

  spec.source_files = "MBWorkspaceCore/*.{h,m,swift}", "MBWorkspaceCore/**/*.{h,m,swift}"

  yaml['DEPENDENCIES']&.each do |name|
    spec.dependency name
  end
  yaml['FORWARD_DEPENDENCIES']&.each do |name, _|
    spec.dependency name
  end
end
