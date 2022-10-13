require_relative 'MBoxWorkspaceTests'

class FeatureStart < MBoxWorkspaceTests
  executable :git
  executable :rm

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

    git!(["-C", @cache_dir, "clone", @repoAddress])
  end

  def setup
    super
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
  end



  ########## Start a new feature From Free Mode ##########


  #1
  def test_start_a_new_feature_from_FreeMode_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #2
  def test_start_a_new_feature_from_free_without_repos
    setup_feature_with_empty("newfeature")
  end


  #3
  def test_start_a_new_feature_from_free__with_committed_data
    testfileName = setup_feature_with_committed_data("FreeMode")


    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  ########## Start a new feature From Feature Mode ##########
  #4
  def test_start_a_new_feature_from_feature_and_uncommitted
    testfileName = setup_feature_with_uncommitted_data("oldfeature")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end

  #5
  def test_start_a_new_feature_from_feature_without_repos
    mbox!(["feature", "start", "oldfeature"])
    assert_repo("oldfeature", [@productName, @repoAddress, "[feature/oldfeature]", "->", @targetBranch])

    setup_feature_with_empty("newfeature")
  end


  

  #6
  def test_start_a_new_feature_from_feature_and_committed
    testfileName = setup_feature_with_committed_data("oldfeature")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #7
  def test_start_a_new_feature_from_free_with_changed_prefix
    mbox!(["feature", "start", "newFeature","--prefix=mbox-test"])
    assert_repo("newFeature", [@productName, @repoAddress, "[mbox-test/newFeature]", "->", @targetBranch])
  end


  #8
  def test_start_a_new_feature_from_feature_with_changed_prefix
    mbox!(["feature", "start", "oldfeature"])
    assert_repo("oldfeature", [@productName, @repoAddress, "[feature/oldfeature]", "->", @targetBranch])

    mbox!(["feature", "start", "newFeature","--prefix=mbox-test"])
    assert_repo("newFeature", [@productName, @repoAddress, "[mbox-test/newFeature]", "->", @targetBranch])
  end


  # ########## Switch a exist feature From Free Mode ##########
  #9
  def test_switch_a_exist_feature_from_free_when_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    mbox!(["feature", "start", "FreeMode"])

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #10
  def test_switch_a_exist_feature_from_free_when_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "start", "FreeMode"])

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
    
  end


  #11
  def test_switch_a_exist_feature_from_free_when_exist_feature_empty
    setup_feature_with_empty("newfeature")

    mbox!(["feature", "start", "FreeMode"])

    setup_feature_with_empty("newfeature")
  end

  #12
  def test_switch_a_exist_feature_with_clear_from_free
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "start", "FreeMode"])

    mbox!(["feature", "start", "newFeature", "--clear"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #13
  def test_switch_a_exist_feature_from_oldfeature_when_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    mbox!(["feature", "start", "oldfeature"])

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end

  #14
  def test_switch_a_exist_feature_from_oldfeature_when_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "start", "oldfeature"])

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
    
  end

  #15
  def test_switch_a_exist_feature_from_oldfeature_when_exist_feature_empty
    setup_feature_with_empty("newfeature")

    mbox!(["feature", "start", "oldfeature"])

    setup_feature_with_empty("newfeature")
  end


  #16
  def test_switch_a_exist_feature_with_clear_from_oldfeature
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "start", "oldfeature"])

    mbox!(["feature", "start", "newFeature", "--clear"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #17  
  def test_switch_free_from_free_when_free_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "FreeMode"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  # #17
  def test_switch_free_from_free_by_tempfeature_when_free_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "tmpFeature"])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "FreeMode"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #18
  def test_switch_free_from_free_when_free_with_committed_data
    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "FreeMode"])

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #19
  def test_switch_free_with_clear_from_free
    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "FreeMode", "--clear"])

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #20
  def test_switch_a_exist_feature_from_exist_feature_when_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end

  # #20
  def test_switch_a_exist_feature_from_exist_feature_by_tempfeature_when_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    mbox!(["feature", "start", "tmpFeature"])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #21
  def test_switch_a_exist_feature_with_clear_from_exist_feature
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #22
  def test_switch_a_exist_feature_from_exist_feature_when_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")


    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
    
  end


  #23
  def test_start_a_new_feature_from_FreeMode_with_uncommitted_data_by_twice
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #24
  def test_start_a_new_feature_from_FreeMode_with_committed_data_by_twice
    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end

  


  #25
  def test_start_a_new_feature_from_FreeMode_without_repos_by_twice
    setup_feature_with_empty("newfeature")
    setup_feature_with_empty("newfeatureTwo")
  end


  #26
  def test_start_a_new_feature_from_old_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("oldfeature")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #27
  def test_start_a_new_feature_from__old_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("oldfeature")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #28
  def test_start_a_new_feature_from__old_feature_without_repos
    testfileName = setup_feature_with_committed_data("oldfeature")
    setup_feature_with_empty("newfeature")
    setup_feature_with_empty("newfeatureTwo")
  end
  

  #29
  def test_start_a_new_feature_from_feature_with_uncommitted_data_keep_changes
    testfileName = setup_feature_with_uncommitted_data("oldfeature")

    mbox!(["feature", "start", "newFeature","--keep-changes"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo","--keep-changes"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  

  # #30
  # def test_start_a_new_feature_from_feature_with_committed_data_keep_changes
  #   testfileName = setup_feature_with_committed_data("oldfeature")

  #   mbox!(["feature", "start", "newFeature","--keep-changes"])
  #   assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  #   assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  #   mbox!(["feature", "start", "newFeatureTwo", "--keep-changes"])
  #   assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
  #   assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  # end

end
