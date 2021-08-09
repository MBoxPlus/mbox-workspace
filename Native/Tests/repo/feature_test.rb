require 'mbox-workspace-tests'

class Feature < MBoxWorkspaceTests
  executable :git
  executable :cp
  executable :rm

  def before_all
    super
    git!(["-C", @cache_dir, "clone", "git@github.com:AFNetworking/AFNetworking.git"])
  end

  def setup
    super
    mbox!(%w"feature start test-feature")
  end

  def assert_remove_repo(repo)
    mbox!(["remove", repo])
    assert_not_contains_file(@tests_dir, repo)
  end

  def test_add_git_url
    mbox!(%w"add git@github.com:AFNetworking/AFNetworking.git master")
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_git_url2
    test_add_git_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_git_url
  end

  def test_add_http_url
    mbox!(%w"add https://github.com/AFNetworking/AFNetworking.git master")
    assert_repo("test-feature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_http_url2
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_http_url
  end

  def test_add_invalid_path
    mbox(["add", "#{@tmp_dir}/non-exists", "master", "--mode=copy"], code: 7)
    assert_repos_is_empty("test-feature")
  end

  def test_add_relative_path
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "../AFNetworking", "master", "--mode=copy"], chdir: @tests_dir)
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_relative_path2
    test_add_relative_path
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_relative_path
  end

  def test_add_path_with_copy_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=copy"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_path_with_copy_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=copy"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_copy_mode2
    test_add_path_with_copy_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_path_with_copy_mode
  end

  def test_add_path_with_move_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=move"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_path_with_move_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=move"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_move_mode2
    test_add_path_with_move_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_path_with_move_mode
  end

  def test_add_path_with_worktree_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "4eaec5b", "--mode=worktree"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  def test_add_path_with_worktree_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=worktree"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
    assert_not_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_worktree_mode2
    test_add_path_with_worktree_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    # Again
    test_add_path_with_worktree_mode
  end

  def test_add_path_with_worktree_mode_branch_checkouted
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"])
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=worktree"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[feature/test-feature]", "->", "[master]"])
  end

  ##################################################################
  def test_add_http_url_then_add_name
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("test-feature", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_http_url_then_add_git_url
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    test_add_git_url
  end

  def test_add_git_url_then_add_name
    test_add_git_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_path_then_add_name
    test_add_path_with_copy_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("test-feature", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_worktree_then_add_name
    test_add_path_with_worktree_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("test-feature")
    mbox(["add", "AFNetworking", "master"], code: 254)
    assert_repos_is_empty("test-feature")
  end
end