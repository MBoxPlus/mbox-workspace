require_relative 'MBoxWorkspaceTests'

class FeatureClean < MBoxWorkspaceTests
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
  def test_feature_clean_without_other_feature
    testfileName = setup_feature_with_uncommitted_data("FreeMode")
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end


  #2
  def test_feature_clean_with_non_changed_new_feature
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    mbox!(["feature", "free"])
    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  

  #3
  def test_feature_clean_with_unmergered_new_feature
    testfileName = setup_feature_with_committed_data("newFeature")
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "free"])
    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  



  #4
  def test_feature_clean_with_non_changed_new_feature_when_new_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    
    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
  end  



  #5
  def test_feature_clean_with_unmergered_new_feature_when_new_feature_in_use
    testfileName = setup_feature_with_committed_data("newFeature")
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  

  #6
  def test_feature_clean_with_two_non_changed_features
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "start", "newFeatureTwo"])


    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature","free"])
    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end




  #7
  def test_feature_clean_with_two_unmergered_features
    fileOne = setup_feature_with_committed_data("newFeature")
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", fileOne)

    fileTwo = setup_feature_with_committed_data("newFeatureTwo")
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", fileTwo)


    mbox!(["feature", "free"])
    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", fileOne)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", fileTwo)
  end


  #8
  def test_feature_clean_with_mergered_new_feature
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    mbox!(["feature", "free"])
    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end 



  #9
  def test_feature_clean_with_mergered_new_feature_when_new_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    mbox!(["feature", "free"])
    testfileName = setup_feature_with_uncommitted_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
   
    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end  



  #10
  def test_feature_clean_with_two_mergered_features
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "start", "newFeatureTwo"])


    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature","free"])
    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #11
  def test_feature_clean_with_two_mergered_features_when_new_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "start", "newFeatureTwo"])


    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature","free"])
    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)  
  end  


  #12
  def test_feature_clean_with_mergered_feature_and_unmergered_feature_when_FreeMode_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    testfileName = setup_feature_with_committed_data("newFeatureTwo")
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "free"])
    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repos_is_empty("newFeature")
  end  



  #13
  def test_feature_clean_with_mergered_feature_and_unmergered_feature_when_unmergered_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    testfileName = setup_feature_with_committed_data("newFeatureTwo")
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "clean"],stdout: /Remove\sFeature\sSuccess/)
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repos_is_empty("newFeature")
  end  


  #14
  def test_feature_clean_with_mergered_feature_and_unmergered_feature_when_mergered_feature_in_use
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

    testfileName = setup_feature_with_committed_data("newFeatureTwo")
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)


    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "clean"],stdout: /Not\sfeature\sto\sclean./)


    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])


    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end  



end
