require 'mbox-workspace-tests'

class FeatureRemove < MBoxWorkspaceTests
  executable :git
  executable :rm

  def before_all
    super
    git!(["-C", @cache_dir, "clone", "https://github.com/AFNetworking/AFNetworking.git"])
  end

  def setup
    super
    mbox!(["add", "#{@cache_dir}/AFNetworking", "master", "--mode=copy"])
    mbox!(["feature", "start", "feature1"])
  end

  def test_remove_current_feature
    mbox(["feature", "remove", "feature1"], code: MBoxErrorCode::USER, stderr: /Could not remove current feature/)
  end

  def test_remove_free_feature
    mbox(["feature", "remove", "FreeMode"], code: MBoxErrorCode::USER, stderr: /Could not remove Free Mode/)
  end

  def test_remove_changed_feature
    rm!("#{@tests_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["feature", "start", "feature2"])
    assert_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
    mbox(["feature", "remove", "feature1"], code: MBoxErrorCode::USER)
  end

  def test_remove_unchanged_feature
    mbox!(["feature", "start", "feature2"])
    mbox!(["feature", "remove", "feature1"])
  end

  def test_nonexists_feature
    mbox(["feature", "remove", "feature_none"], code: MBoxErrorCode::USER)
  end
end
