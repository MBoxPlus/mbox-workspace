require_relative 'MBoxWorkspaceTests'

class FeatureRemove < MBoxWorkspaceTests
  executable :git
  executable :rm

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
  def test_feature_remove_without_feature_name
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox(["feature", "remove"],stdout: /Need\sa\sfeature\sname/)

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end


  #2
  def test_feature_remove_invalid_feature_name
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox(["feature", "remove","nonexistsFeature"],{code: MBoxErrorCode::USER, stderr:/Could\snot\sfind\sfeature/})

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end

  #3
  def test_feature_remove_FreeMode
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox(["feature", "remove","FreeMode"],{code: MBoxErrorCode::USER, stderr:/Could\snot\sremove\sFree\sMode/})

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end

  #4
  def test_feature_remove_feature_name_in_use
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox(["feature", "remove","newFeature"],{code: MBoxErrorCode::USER, stderr:/Could\snot\sremove\scurrent\sfeature/})

    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #5
  def test_feature_remove_existing_feature_name_without_change_from_FreeMode
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "free"])

    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "remove","newFeature"],stdout: /Remove\sFeature\sSuccess/)


    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end



  #6
  def test_feature_remove_existing_feature_name_with_uncommitted_data_from_FreeMode
    testfileName = setup_feature_with_uncommitted_data("newFeature")

    mbox!(["feature", "free"])
    mbox(["feature", "remove","newFeature"],{code: MBoxErrorCode::USER, stderr: /has\suncommit\schanges/})

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end

 

  #7
  def test_feature_remove_existing_feature_name_with_unmerged_commits_from_FreeMode
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "free"])
    mbox(["feature", "remove","newFeature"],{code: MBoxErrorCode::USER, stderr: /has\sunmerged\scommit/})

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

  end



  #8
  def test_feature_remove_existing_feature_name_without_unmerged_commits_force
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "free"])

    mbox!(["feature", "remove","newFeature","--force"],stdout: /Remove\sFeature\sSuccess/)

    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end
 
  #9
  def test_feature_remove_existing_feature_name_with_unmerged_commits_force
    testfileName = setup_feature_with_committed_data("newFeature")

    mbox!(["feature", "free"])
    mbox!(["feature", "remove","newFeature","--force"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end



  #10
  def test_feature_remove_all_feature
    mbox!(["feature", "start", "newFeature"])
    mbox!(["feature", "start", "newFeatureTwo"])

    mbox!(["feature", "free"])
    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "remove","--all"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeature","--clear"])
    assert_repo("newFeature", nil)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", nil)
  end



  #11
  def test_feature_remove_existing_feature_name_include_repo

    mbox!(["feature", "start", "newFeature"])
    mbox!(["add", "#{@cache_dir}/#{@productTwo}", @targetBranch, "--mode=copy"])

    assert_repos("newFeature", [[@productName, @repoAddress, @targetBranch],[@productTwo, @repoTwo, @targetBranch]])
    assert_contains_file(@store_dir, @productName)
    assert_contains_file(@store_dir, @productTwo)

    mbox!(["feature", "free"])
    mbox!(["feature", "remove","newFeature","--include-repo"],stdout: /Remove\sFeature\sSuccess/)
    assert_not_contains_file(@store_dir, @productTwo)
    assert_contains_file(@store_dir, @productName)

    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])

  end


  #12
  def test_feature_remove_existing_feature_from_other_feature
    mbox!(["feature", "start", "newFeature"])

    testfileName = setup_feature_with_committed_data("FreeMode")

    mbox!(["feature", "start", "newFeatureTwo"])

    mbox!(["feature", "remove","newFeature"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "free"])

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)
  end


  #13
  def test_feature_remove_all_feature_with_unmergered_committed_data
    testfileName = setup_feature_with_committed_data("newFeature")
    testfileNameTwo = setup_feature_with_committed_data("newFeatureTwo")

    mbox!(["feature", "free"])

    mbox(["feature", "remove","--all"],code: MBoxErrorCode::USER)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileNameTwo)
  end




  #14
  def test_feature_remove_all_feature_with_unmergered_committed_data_and_the_other_feature_unchanged
    mbox!(["feature", "start", "newFeature"])
    testfileNameTwo = setup_feature_with_committed_data("newFeatureTwo")

    testfileNameFree = setup_feature_with_committed_data("FreeMode")

    mbox(["feature", "remove","--all"],code: MBoxErrorCode::USER)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileNameFree)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_contains_file("#{@tests_dir}/#{@productName}", testfileNameTwo)
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileNameFree)
  end


  #15
  def test_feature_remove_all_feature_with_unmergered_committed_data_and_the_other_feature_unchanged_force
    testfileName = setup_feature_with_committed_data("newFeature")
    testfileNameTwo = setup_feature_with_committed_data("newFeatureTwo")

    mbox!(["feature", "free"])

    mbox!(["feature", "remove","--all","--force"],stdout: /Remove\sFeature\sSuccess/)

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileName)

    mbox!(["feature", "start", "newFeatureTwo"])
    assert_repo("newFeatureTwo", [@productName, @repoAddress, "[feature/newFeatureTwo]", "->", @targetBranch])
    assert_not_contains_file("#{@tests_dir}/#{@productName}", testfileNameTwo)
  end


end
