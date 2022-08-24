require_relative 'MBoxWorkspaceTests'

class FeatureExport < MBoxWorkspaceTests
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

    @targetBranch = "master"

    @productTwo = "AFNetworking"
    @repoTwo = "https://github.com/AFNetworking/AFNetworking.git"


    @productName = "ObjCCommandLine"
    @repoAddress = "https://github.com/dijkst/ObjCCommandLine.git"



    git!(["-C", @cache_dir, "clone", @repoAddress])
    git!(["-C", @cache_dir, "clone", @repoTwo])
  end

 
  #1
  def test_export_FreeMode_from_FreeMode
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
    
    mbox!(["feature", "export"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal @repoAddress, repo["url"]
      assert_equal @targetBranch, repo["last_branch"]
      assert_equal "branch", repo["last_type"]
    }
  end

  #2
  def test_export_FreeMode_from_feature
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])    


    mbox!(["feature", "start", "feature2"])
    mbox!(["remove", @productName])
    assert_repo("feature2", nil)


    mbox!(["feature", "export", "FreeMode"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal @repoAddress, repo["url"]
      assert_equal @targetBranch, repo["last_branch"]
      assert_equal "branch", repo["last_type"]
    }
  end


  #3
  def test_export_feature_from_current_feature
    mbox!(["feature", "start", "feature1"])
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo("feature1", [@productName, @repoAddress,"[feature/feature1]", @targetBranch])


    mbox!(["feature", "export"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "feature1", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal @repoAddress, repo["url"]
      assert_equal "feature/feature1", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
      assert_equal @targetBranch, repo["target_branch"]
    }
  end


  #4
  def test_export_feature_from_FreeMode
    mbox!(["feature", "start", "feature1"])
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo("feature1", [@productName, @repoAddress,"[feature/feature1]", @targetBranch]) 


    mbox!(["feature", "free"])
    mbox!(["feature", "export", "feature1"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "feature1", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal @repoAddress, repo["url"]
      assert_equal "feature/feature1", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
      assert_equal @targetBranch, repo["target_branch"]
    }
  end




  #5
  def test_export_fail_if_not_push_branch
    tempFeature =  "tempFeature" + (0...8).map { (65 + rand(26)).chr }.join

    mbox!(["feature", "start", tempFeature])
    mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    assert_repo(tempFeature, [@productName, @repoAddress,"[feature/#{tempFeature}]", @targetBranch])
    mbox(["feature", "export"], code: MBoxErrorCode::USER, stderr: /is not pushed to the remote/)
  end

  #6
  def test_export_fail_if_not_find_feature
    mbox(["feature", "export", "nonexist"], code: MBoxErrorCode::USER, stderr: /Could not find a feature which named `nonexist`/)
  end
  
end
