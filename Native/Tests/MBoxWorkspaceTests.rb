require 'mbox-dev/mbox-tests'

class MBoxWorkspaceTests < MBoxTests
  executable :git

  def output_verbose_log
    Dir[@tests_dir + "/.mbox/logs/*/CLI/*.verbose.log"].sort.each do |path|
      puts File.read(path)
      puts ""
    end
  end

  def should_setup_workspace
    true
  end

  def setup_workspace_group
    nil
  end

  def setup_workspace_plugins
    []
  end

  def mbox_init_with_workspace_group_and_workspace_plugins
    return unless should_setup_workspace
    cmd = ["init"]
    cmd << setup_workspace_group unless setup_workspace_group.nil?
    cmd.concat setup_workspace_plugins.map { |name| ["--plugin", name] }
    cmd.flatten!
    mbox!(cmd)
  end


  def setup_feature_with_uncommitted_data(featureName = "oldfeature")
    mbox!(["feature", "start", featureName])
    assert_repo(featureName, [@productName, @repoAddress, @targetBranch])
    
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/#{@productName}","add",testfileName])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    return testfileName
  end

  def setup_feature_with_committed_data(featureName = "oldfeature")
    mbox!(["feature", "start", featureName])
    assert_repo(featureName, [@productName, @repoAddress, @targetBranch])
    
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/#{@productName}","add",testfileName])
    git!(["-C","#{@tests_dir}/#{@productName}","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
    return testfileName
  end

  def setup_feature_with_empty(featureName = "oldfeature")
    mbox!(["feature", "start", featureName, "--clear"])
    assert_repo(featureName, nil)
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
  #     └── tests(@test_dir)
  #     │   └── .mbox(created after mbox init)
  #     │       └── repos(@store_dir)
  #     └── ...
  #
  def setup
    super

    mbox_init_with_workspace_group_and_workspace_plugins()
    @store_dir = @tests_dir + "/.mbox/repos"
  end

  def assert_repos_is_empty(feature)
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+It is empty!/)
  end

  def assert_repo(feature, repo)
    regex = repo ? repo.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") : "It is empty!"
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*#{regex}/m)
    assert_contains_file(@tests_dir, repo.first) if repo
  end

  def assert_repos(feature, repos)
    repos.each do |repo|
      regex = repo ? repo.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") : "It is empty!"
      mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*#{regex}/m)
      assert_contains_file(@tests_dir, repo.first) if repo
    end

    # regex = repos.map { |lines| lines.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") }.join("[\n\s]+")

    # mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+#{regex}/)
    # assert_contains_file(@tests_dir, repos.map { |repo| repo.first })
  end
end