require_relative 'MBoxWorkspaceTests'

class FeatureFree < MBoxWorkspaceTests
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

    @productTwo = "ObjCCommandLine"
    @repoTwo = "https://github.com/dijkst/ObjCCommandLine.git"

    git!(["-C", @cache_dir, "clone", @repoAddress])
    git!(["-C", @cache_dir, "clone", @repoTwo])
  end

  def setup
    super
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
  end

  #1
  def test_feature_free_from_FreeMode_feature_with_two_repo
    mbox!(["add", "#{@cache_dir}/#{@productTwo}", @targetBranch,"--mode=copy"])
    assert_repos("FreeMode", [[@productName, @repoAddress, @targetBranch],[@productTwo, @repoTwo, @targetBranch]])


    mbox!(["feature", "free"])
    assert_repos("FreeMode", [[@productName, @repoAddress, @targetBranch],[@productTwo, @repoTwo, @targetBranch]])

  end



  #2
  def test_feature_free_from_FreeMode_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "free"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end

  #3
  def test_feature_free_from_FreeMode_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "free"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



   #4
   def test_feature_free_from_feature_with_two_repo
    mbox!(["feature", "start","newFeature"])
    mbox!(["add", "#{@cache_dir}/#{@productTwo}", @targetBranch,"--mode=copy"])
    assert_repos("newFeature", [[@productName, @repoAddress, @targetBranch],[@productTwo, @repoTwo, @targetBranch]])


    mbox!(["feature", "free"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", @productTwo)
  end


  #5
  def test_feature_free_from_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    mbox!(["feature", "free"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start","newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


  end  

  #6
  def test_feature_free_from_feature_with_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "free"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start","newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  

end
