require_relative 'MBoxWorkspaceTests'

class MBoxNew < MBoxWorkspaceTests
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

    #git!(["-C", @cache_dir, "clone", @repoAddress])
    #git!(["-C", @cache_dir, "clone", @repoTwo])
  end


  def setup
    super
    #mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
  end

  #1
  def test_new_from_FreeMode
    mbox!(["feature", "free"])
    mbox!(["new", "testrepo"])
    assert_repo("FreeMode", ["testrepo", "master"])
  end


  #2
  def test_new_from_FreeMode_with_branch
    mbox!(["feature", "free"])
    mbox!(["new", "testrepo","develop"])
    assert_repo("FreeMode", ["testrepo", "develop"])
  end


  #3
  def test_new_from_FreeMode_by_twice
    mbox!(["feature", "free"])
    mbox!(["new", "testrepo"])
    assert_repo("FreeMode", ["testrepo", "master"])

    mbox!(["new", "testrepo2","develop"])
    assert_repo("FreeMode", ["testrepo2", "develop"])
  end

  #4
  def test_new_exist_repo_from_FreeMode
    mbox!(["new", "testrepo"])
    assert_repo("FreeMode", ["testrepo", "master"])

    mbox(["new", "testrepo"],code: MBoxErrorCode::USER)
    assert_repo("FreeMode", ["testrepo", "master"])
  end


  #5
  def test_new_from_feature
    mbox!(["feature", "start", "newFeature"])
    mbox!(["new", "testrepo"])
    assert_repo("newFeature", ["testrepo", "feature/newFeature","master"])

    mbox!(["feature", "free"])
    assert_repos_is_empty("FreeMode")
  end

  #6
  def test_new_from_feature_with_branch
    mbox!(["feature", "start", "newFeature"])
    mbox!(["new", "testrepo","develop"])
    assert_repo("newFeature", ["testrepo", "feature/newFeature","develop"])

    mbox!(["feature", "free"])
    assert_repos_is_empty("FreeMode")

  end



  #7
  def test_new_from_feature_by_twice
    mbox!(["feature", "start", "newFeature"])
    mbox!(["new", "testrepo"])
    assert_repo("newFeature", ["testrepo", "feature/newFeature","master"])


    mbox!(["new", "testrepo2","develop"])
    assert_repo("newFeature", ["testrepo2", "feature/newFeature","develop"])
    assert_repo("newFeature", ["testrepo", "feature/newFeature","master"])
    
  end

    #8
    def test_new_a_exist_repo_from_feature
        mbox!(["feature", "start", "newFeature"])
        mbox!(["new", "testrepo"])
        assert_repo("newFeature", ["testrepo", "feature/newFeature","master"])
    
        mbox(["new", "testrepo"],code: MBoxErrorCode::USER)
        assert_repo("newFeature", ["testrepo", "feature/newFeature","master"])
    end
    
end
