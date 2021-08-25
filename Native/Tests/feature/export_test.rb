require 'mbox-workspace-tests'

class FeatureExport < MBoxWorkspaceTests
  executable :git
  executable :rm

  def before_all
    super
    git!(["-C", @cache_dir, "clone", "https://github.com/dijkst/ObjCCommandLine.git"])
  end

  def test_export_current_free
    mbox!(["add", "#{@cache_dir}/ObjCCommandLine", "master", "--mode=copy"])
    assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"])
    mbox!(["feature", "export"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal "https://github.com/dijkst/ObjCCommandLine.git", repo["url"]
      assert_equal "master", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
    }
  end

  def test_export_other_free
    mbox!(["add", "#{@cache_dir}/ObjCCommandLine", "master", "--mode=copy"])
    assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"])

    mbox!(["feature", "start", "feature2"])
    mbox!(["remove", "ObjCCommandLine"])
    assert_repo("feature2", nil)

    mbox!(["feature", "export", "FreeMode"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal "https://github.com/dijkst/ObjCCommandLine.git", repo["url"]
      assert_equal "master", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
    }
  end

  def test_export_current_feature
    mbox!(["feature", "start", "feature1"])
    mbox!(["add", "#{@cache_dir}/ObjCCommandLine", "master", "--mode=copy"])
    assert_repo("feature1", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[feature/feature1]", "[master]"])
    mbox!(["feature", "export"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "feature1", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal "https://github.com/dijkst/ObjCCommandLine.git", repo["url"]
      assert_equal "feature/feature1", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
      assert_equal "master", repo["target_branch"]
    }
  end

  def test_export_other_feature
    mbox!(["feature", "start", "feature1"])
    mbox!(["add", "#{@cache_dir}/ObjCCommandLine", "master", "--mode=copy"])
    assert_repo("feature1", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[feature/feature1]", "[master]"])

    mbox!(["feature", "free"])
    mbox!(["feature", "export", "feature1"]) { |code, stdout, stderr|
      assert_equal(0, code)
      json = JSON.parse(stdout)
      assert_equal "feature1", json["name"]
      assert_equal 1, json["repos"].count
      repo = json["repos"].first
      assert_equal "https://github.com/dijkst/ObjCCommandLine.git", repo["url"]
      assert_equal "feature/feature1", repo["last_branch"]
      assert_equal "branch", repo["last_type"]
      assert_equal "master", repo["target_branch"]
    }
  end

  def test_export_fail_if_not_push_branch
    mbox!(["feature", "start", "feature2"])
    mbox!(["add", "#{@cache_dir}/ObjCCommandLine", "master", "--mode=copy"])
    assert_repo("feature2", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[feature/feature2]", "[master]"])
    mbox(["feature", "export"], code: MBoxErrorCode::USER, stderr: /is not pushed to the remote/)
  end

  def test_export_fail_if_not_find_feature
    mbox(["feature", "export", "nonexist"], code: MBoxErrorCode::USER, stderr: /Could not find a feature which named `nonexist`/)
  end
end
