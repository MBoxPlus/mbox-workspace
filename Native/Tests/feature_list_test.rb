require_relative 'MBoxWorkspaceTests'

class FeatureList < MBoxWorkspaceTests
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
    @productName = "repoForTestFeatureList"
    @targetBranch = "master"
  end

  def setup
    super
    mbox!(["new", "#{@productName}", "#{@targetBranch}"])
  end


    #1
    def test_feature_list_without_other_feature
      assert_repo("FreeMode", [@productName,  @targetBranch])
      mbox!(["feature", "list"],stdout: /\e\[33m\[FreeMode\].*#{@productName}.*/m)
    end




    #2
    def test_feature_list_with_empty_repo_in_FreeMode
      mbox!(["feature", "free"])
      mbox!(["remove", @productName, "--force"])
      assert_repos_is_empty("FreeMode")
      mbox!(["feature", "list"],stdout: /\e\[33m\[FreeMode\][\n\s]*\[*/)
    end


    #3
    def test_feature_list_with_new_feature
      mbox!(["feature", "start", "newFeature"])
      assert_repo("newFeature", [@productName, "[feature/newFeature]", "->", @targetBranch])
      mbox!(["feature", "free"])
      mbox!(["feature", "list"],stdout: /\e\[33m\[FreeMode\].*#{@productName}.*/m)
      mbox!(["feature", "list"],stdout: /\[newFeature\][\n\s]*#{@productName}.*/m)
    end  


    

    #4
    def test_feature_list_with_empty_repo_in_new_feature
      mbox!(["feature", "start", "newFeature"])
      assert_repo("newFeature", [@productName, "[feature/newFeature]", "->", @targetBranch])
      mbox!(["remove", @productName, "--force"])
      assert_repos_is_empty("newFeature")

      mbox!(["feature", "list"],stdout: /\[FreeMode\].*#{@productName}.*/m)
      mbox!(["feature", "list"],stdout: /\e\[33m\[newFeature\][\n\s]*\[*/m)
    end



  #5
  def test_feature_list_with_new_feature_when_new_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName,  "[feature/newFeature]", "->", @targetBranch])

    mbox!(["feature", "list"],stdout: /\e\[33m\[newFeature\].*#{@productName}.*/m)
    mbox!(["feature", "list"],stdout: /\[FreeMode\].*#{@productName}.*/m)
  end


  #6
  def test_feature_list_with_two_features
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, "[feature/newFeature]", "->", @targetBranch])


    mbox!(["feature", "start", "newFeatureTwo"])

    mbox!(["feature", "free"])

    mbox!(["feature", "list"],stdout: /\e\[33m\[FreeMode\].*#{@productName}.*/m)
    mbox!(["feature", "list"],stdout: /\[newFeature\]/)
    mbox!(["feature", "list"],stdout: /\[newFeatureTwo\]/)

  end


  #7
  def test_feature_list_with_two_features_when_new_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, "[feature/newFeature]", "->", @targetBranch])

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, "[feature/newFeatureTwo]", "->", @targetBranch])

    mbox!(["feature", "list"],stdout: /\[newFeature\].*#{@productName}.*/m)
    mbox!(["feature", "list"],stdout: /\e\[33m\[newFeatureTwo\].*#{@productName}.*/m)
    mbox!(["feature", "list"],stdout: /\[FreeMode\].*#{@productName}.*/m)
  end

end