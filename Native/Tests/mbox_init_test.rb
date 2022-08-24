require 'mbox-dev/mbox-tests'

class MBoxInit < MBoxTests
  executable :git

  def output_verbose_log
    Dir[@tests_dir + "/.mbox/logs/*/CLI/*.verbose.log"].sort.each do |path|
      puts File.read(path)
      puts ""
    end
  end


  def mbox_init_with_workspace_group_and_workspace_plugins(workspaceGroup = nil, workspacePlugins = [])
    cmd = ["init"]
    cmd << workspaceGroup unless workspaceGroup.nil?
    cmd.concat workspacePlugins.map { |name| ["--plugin", name] }
    cmd.flatten!
    return cmd
  end

  #create temporary folders
  #(@tmp_root)
  # ├── caches(@cache_dir)
  # │   
  # │       
  # │           
  # └── (@tmp_dir)
  #     └── home(@home_dir)
  #     │   └── .mbox
  #     │      
  #     └── tests(@tests_dir)
  #     │   └── .mbox(created after mbox init)
  #     │       └── repos(@store_dir)
  #     └── ...
  #

  def assert_repos_is_empty(feature)
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+It is empty!/)
  end

  def assert_repo(feature, repo)
    regex = repo ? repo.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") : "It is empty!"
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*#{regex}/m)
    assert_contains_file(@tests_dir, repo.first) if repo
  end


  #1
  def test_mbox_init_in_an_empty_folder
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox!(cmd,stdout: /Init\smbox\sworkspace\ssuccess/)
      assert_contains_file(@tests_dir, '.mbox')
  end

  #2
  def test_mbox_init_in_a_non_empty_folder
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox!(cmd,stdout: /Init\smbox\sworkspace\ssuccess/)
      assert_contains_file(@tests_dir, '.mbox')
  end


  #3
  def test_mbox_init_in_workspace
      test_mbox_init_in_an_empty_folder()
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox(cmd,{code: MBoxErrorCode::USER, stderr: /there\sis\sa\smbox/})
  end

  #4
  def test_mbox_init_in_subdirectory_of_workspace
      test_mbox_init_in_an_empty_folder()
      subdir = @tests_dir + "/subdir"
      FileUtils.mkdir_p(subdir)
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox(cmd,{code: MBoxErrorCode::USER, chdir: subdir})
  end


  #5
  def test_mbox_init_in_repo
      git!(["-C", @tests_dir,"init"])
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox(cmd,{code: MBoxErrorCode::USER, stderr: /Could\snot\sinit\sa\smbox\sin\sa\sgit\srepository/})
  end


  #6
  def test_mbox_init_in_root_directory
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox(cmd,{code: MBoxErrorCode::USER, chdir: '/', stderr: /Could\snot\sinit\sa\smbox/})
  end

  #7
  def test_mbox_init_in_an_empty_folder_with_plugin_group_ios
      cmd = mbox_init_with_workspace_group_and_workspace_plugins()
      mbox(cmd,{code: MBoxErrorCode::USER, chdir: Dir.home})
  end


  #8
  def test_mbox_init_with_folder_name
      mbox!(["init","--name=newdir"],stdout: /create\sMBox\sworkspace\sfolder/)
      newdir = @tests_dir + "/newdir"
      assert_contains_file(newdir, '.mbox')
  end



  #9
  def test_mbox_init_with_exist_folder_name
      newdir = @tests_dir + "/newdir"
      FileUtils.mkdir_p(newdir)
      mbox!(["init","--name=newdir"],stdout: /create\sMBox\sworkspace\sfolder/)
  end




#10
def test_mbox_init_with_one_plugin
    cmd = mbox_init_with_workspace_group_and_workspace_plugins(nil, ["MBoxFork"])
    mbox!(cmd,stdout: /Init\smbox\sworkspace\ssuccess/)
    assert_contains_file(@tests_dir, '.mboxconfig')
    mbox!(["config", "-w"], stdout: /MBoxFork/)
end

#11
def test_mbox_init_with_two_plugins
    cmd = mbox_init_with_workspace_group_and_workspace_plugins(nil, ["MBoxFork", "MBoxTower"])
    mbox!(cmd,stdout: /Init\smbox\sworkspace\ssuccess/)
    assert_contains_file(@tests_dir, '.mbox')
    mbox!(["config", "-w"], stdout: /MBoxFork/)
    mbox!(["config", "-w"], stdout: /MBoxTower/)
end

#12
def test_mbox_init_with_three_plugins
    cmd = mbox_init_with_workspace_group_and_workspace_plugins(nil, ["MBoxFork", "MBoxTower", "MBoxRuby"])
    mbox!(cmd,stdout: /Init\smbox\sworkspace\ssuccess/)
    assert_contains_file(@tests_dir, '.mbox')
    mbox!(["config", "-w"], stdout: /MBoxFork/)
    mbox!(["config", "-w"], stdout: /MBoxTower/)
    mbox!(["config", "-w"], stdout: /MBoxRuby/)
end

    

end