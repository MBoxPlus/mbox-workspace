require_relative 'MBoxWorkspaceTests'

class MBoxAdd < MBoxWorkspaceTests
  executable :git
  executable :rm
  executable :cp

  def should_setup_workspace
    true
  end

  def setup_workspace_group
    return nil
  end

  def setup_workspace_plugins
    []
  end


  def before_all
    super
    @productName = "AFNetworking"
    @repoAddress = "https://github.com/AFNetworking/AFNetworking.git"
    @targetBranch = "master"

    @productTwo = "ObjCCommandLine"
    @repoTwo = "https://github.com/dijkst/ObjCCommandLine.git"

    git!(["-C", @cache_dir, "clone", @repoAddress])
    #git!(["-C", @cache_dir, "clone", @repoTwo])
  end

  def setup
    super
    mbox!(%w"feature start newFeature")
  end

  def assert_remove_repo(repo)
    mbox!(["remove", repo])
    assert_not_contains_file(@tests_dir, repo)
  end


  #1
  def test_add_git_url
    mbox!(["add", @repoAddress, @targetBranch])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end


  #2
  def test_add_git_url2
    test_add_git_url
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    test_add_git_url
  end

  #3
  def test_add_http_url
    mbox!(["add", @repoAddress, @targetBranch])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end

  #4
  def test_add_http_url2
    test_add_http_url
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    test_add_http_url
  end


  #5
  def test_add_invalid_path
    mbox(["add", "#{@tmp_dir}/non-exists", "master", "--mode=copy"], code: 7)
    assert_repos_is_empty("newFeature")
  end


  #6
  def test_add_relative_path
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")
    mbox!(["add", "../#{@productName}", @targetBranch, "--mode=copy"], chdir: @tests_dir)
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end


  #7
  def test_add_relative_path2
    test_add_relative_path
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    mbox(["add", "../#{@productName}", @targetBranch, "--mode=copy"], chdir: @tests_dir, code: MBoxErrorCode::USER)
  end



  #8
  def test_add_path_with_copy_mode
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")
    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end


  #9
  def test_add_path_by_copy_mode_keep_changes_with_uncommitted_data
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")


    testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
    #git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tmp_dir}/#{@productName}", testfileName)

    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=copy", "--keep-local-changes"])

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  # #9
  def test_add_path_by_copy_mode_keep_changes_with_committed_data
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")


    testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
    git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tmp_dir}/#{@productName}", testfileName)

    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=copy",  "--keep-local-changes"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    assert_contains_file("#{@tmp_dir}/#{@productName}", testfileName)
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end

  # # #9
  # def test_add_path_by_copy_mode_with_committed_data_and_uncommitted_data
  #   cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")


  #   testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
  #   testfileName = File.basename(testfile.path)
  #   git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
  #   git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])
  #   assert_contains_file("#{@tmp_dir}/#{@productName}", testfileName)

  #   testuncommitted = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
  #   uncommittedName = File.basename(testuncommitted.path)
  #   git!(["-C","#{@tmp_dir}/#{@productName}","add",uncommittedName])


  #   mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=copy"])

  #   assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  #   assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  #   assert_not_contains_file("#{@tests_dir}/#{@productName}", uncommittedName)
  # end

  
  #10
  def test_add_path_with_copy_mode2
    test_add_path_with_copy_mode
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    mbox(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=copy"], code: MBoxErrorCode::USER)
  end


  #11
  def test_add_path_with_move_mode
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")
    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=move"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

  end

  #12
  def test_add_path_by_move_mode_keep_changes_with_uncommitted_data
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")

    testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
    #git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])
    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=move", "--keep-local-changes"])

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end


  #  #12
  def test_add_path_with_move_mode_keep_changes_with_committed_data
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")

    testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
    git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])
    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=move", "--keep-local-changes"])  #"--checkout-from-commit"

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #   # #12
  # def test_add_path_by_move_mode_with_committed_data_and_uncommitted_data
  #   cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")


  #   testfile = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
  #   testfileName = File.basename(testfile.path)
  #   git!(["-C","#{@tmp_dir}/#{@productName}","add",testfileName])
  #   git!(["-C","#{@tmp_dir}/#{@productName}","commit","-m" "\'test feature\'"])



  #   testuncommitted = Tempfile.new("MboxTest", "#{@tmp_dir}/#{@productName}")
  #   uncommittedName = File.basename(testuncommitted.path)
  #   git!(["-C","#{@tmp_dir}/#{@productName}","add",uncommittedName])
    

  #   assert_contains_file("#{@tmp_dir}/#{@productName}", testfileName)
  #   assert_contains_file("#{@tmp_dir}/#{@productName}", uncommittedName)


  #   mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=move"])

  #   assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  #   assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  #   assert_not_contains_file("#{@tests_dir}/#{@productName}", uncommittedName)
  # end

  #13
  def test_add_path_with_move_mode2
    test_add_path_with_move_mode
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    mbox!(["add", @productName, @targetBranch])
  end

  #14
  def test_add_path_with_worktree_mode
    cp!(["-r", "#{@cache_dir}/#{@productName}", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/#{@productName}")
    mbox!(["add", "#{@tmp_dir}/#{@productName}", @targetBranch, "--mode=worktree"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end


  #15
  def test_add_path_with_worktree_mode2
    test_add_path_with_worktree_mode
    assert_remove_repo(@productName)
    assert_repos_is_empty("newFeature")
    # Again
    test_add_path_with_worktree_mode
  end



  ##################################################################
    #16
    def test_add_http_url_then_add_name
      test_add_http_url
      assert_remove_repo(@productName)
      assert_repos_is_empty("newFeature")
      mbox!(["add", @productName, @targetBranch])
      assert_repo("newFeature", [@productName, @repoAddress,  @targetBranch])
    end

    #17
    def test_add_http_url_then_add_git_url
      test_add_http_url
      assert_remove_repo(@productName)
      assert_repos_is_empty("newFeature")
      test_add_git_url
    end

    #18
    def test_add_git_url_then_add_name
      test_add_git_url
      assert_remove_repo(@productName)
      assert_repos_is_empty("newFeature")
      mbox!(["add", @productName, @targetBranch])
      assert_repo("newFeature", [@productName, @repoAddress,  @targetBranch])
    end

    #19
    def test_add_path_then_add_name
      test_add_path_with_copy_mode
      assert_remove_repo(@productName)
      assert_repos_is_empty("newFeature")
      mbox!(["add", @productName, @targetBranch])
      assert_repo("newFeature", [@productName, @repoAddress,  @targetBranch])
    end

    #20
    def test_add_worktree_then_add_name
      test_add_path_with_worktree_mode
      assert_remove_repo(@productName)
      assert_repos_is_empty("newFeature")
      mbox(["add", @productName, @targetBranch], code: 254)
      assert_repos_is_empty("newFeature")
    end

    
end