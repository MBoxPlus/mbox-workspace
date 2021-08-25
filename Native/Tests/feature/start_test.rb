require 'mbox-workspace-tests'

class FeatureStart < MBoxWorkspaceTests
  executable :git
  executable :rm

  def before_all
    super
    git!(["-C", @cache_dir, "clone", "https://github.com/AFNetworking/AFNetworking.git"])
  end

  def setup
    super
    mbox!(["add", "#{@cache_dir}/AFNetworking", "master", "--mode=copy"])
  end

  def setup_feature(name)
    mbox!(["feature", "start", name])
    rm!("#{@tests_dir}/AFNetworking/CHANGELOG.md")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
    assert_repo(name, ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/#{name}]", "->", "[master]"])
  end

  ########## Start a new feature From Free Mode ##########
  def test_start_a_new_feature_from_free_with_repos_and_changes
    rm!("#{@tests_dir}/AFNetworking/CHANGELOG.md")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/newFeature]", "->", "[master]"])
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_start_a_new_feature_from_free_without_repos
    mbox!(["feature", "start", "newFeature", "--clear"])
    assert_repo("newFeature", nil)
  end

  def test_start_a_new_feature_from_free_without_changes
    rm!("#{@tests_dir}/AFNetworking/CHANGELOG.md")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
    mbox!(["feature", "start", "newFeature", "--no-keep-changes"])
    assert_repo("newFeature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/newFeature]", "->", "[master]"])
    assert_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  ########## Start a new feature From Feature Mode ##########
  def test_start_a_new_feature_from_feature
    setup_feature("feature1")

    mbox!(["feature", "start", "newFeature"])
    assert_repo("newFeature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/newFeature]", "->", "[master]"])
    assert_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_start_a_new_feature_from_feature_without_repos
    setup_feature("feature1")

    mbox!(["feature", "start", "newFeature", "--clear"])
    assert_repo("newFeature", nil)
    assert_not_contains_file(@tests_dir, "AFNetworking")
  end

  def test_start_a_new_feature_from_feature_with_changes
    setup_feature("feature1")

    mbox!(["feature", "start", "newFeature", "--keep-changes"])
    assert_repo("newFeature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/newFeature]", "->", "[master]"])
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_start_a_new_feature_from_feature_without_changes
    setup_feature("feature1")

    mbox!(["feature", "start", "newFeature", "--no-keep-changes"])
    assert_repo("newFeature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/newFeature]", "->", "[master]"])
    assert_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  ########## Switch a exist feature From Free Mode ##########
  def test_switch_a_exist_feature_from_free
    setup_feature("feature1")
    mbox!(["feature", "free"])
    mbox!(["remove", "AFNetworking", "--force"])

    mbox!(["feature", "start", "feature1"])
    assert_repo("feature1", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/feature1]", "->", "[master]"])
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  ########## Switch a exist feature From Feature Mode ##########
  def test_switch_a_exist_feature_from_feature
    setup_feature("feature1")
    setup_feature("feature2")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
    mbox!(["remove", "AFNetworking", "--force"])

    mbox!(["feature", "start", "feature1"])
    assert_repo("feature1", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/feature1]", "->", "[master]"])
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end
end
