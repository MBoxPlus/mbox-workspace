require_relative 'MBoxWorkspaceTests'

class FeatureFinish < MBoxWorkspaceTests
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

  #1
  def test_feature_finish_from_FreeMode
    mbox(["feature", "finish"],{code: MBoxErrorCode::USER, stderr:/Could\snot\sfinish\sthe\sFree\sMode/})
  end


  #2
  def test_feature_finish_from_feature_with_uncommitted_data
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox(["feature", "finish"],{code: MBoxErrorCode::USER})

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #3
  def test_feature_finish_from_feature_with_unmergered_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox(["feature", "finish"],{code: MBoxErrorCode::USER})

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end

  #4
  def test_feature_finis_from_feature_with_mergered_data
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "finish"])

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repos_is_empty("newFeature")
  end

 #5
  def test_feature_finish_from_feature_with_uncommitted_data_force
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "finish","--force"])

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repos_is_empty("newFeature")
  end


end
