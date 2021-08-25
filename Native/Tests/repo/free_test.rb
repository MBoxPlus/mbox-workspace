require 'mbox-workspace-tests'

class Free < MBoxWorkspaceTests
  executable :git
  executable :cp
  executable :rm

  def before_all
    super
    git!(["-C", @cache_dir, "clone", "https://github.com/AFNetworking/AFNetworking.git"])
  end

  def assert_remove_repo(repo)
    mbox!(["remove", repo])
    assert_not_contains_file(@tests_dir, repo)
  end

  def test_remove_nonexists
    mbox(["remove", "repo"], code: 254)
  end

  def test_add_git_url
    mbox!(%w"add https://github.com/AFNetworking/AFNetworking.git master")
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking@AFNetworking")
  end

  def test_add_git_url2
    test_add_git_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    test_add_git_url
  end

  def test_add_http_url
    mbox!(%w"add https://github.com/AFNetworking/AFNetworking.git master")
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking@AFNetworking")
  end

  def test_add_http_url2
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    test_add_http_url
  end

  def test_add_invalid_path
    mbox(["add", "#{@tmp_dir}/non-exists", "master", "--mode=copy"], code: 7)
    assert_repos_is_empty("FreeMode")
  end

  def test_add_relative_path
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "../AFNetworking", "master", "--mode=copy"], chdir: @tests_dir)
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
  end

  def test_add_relative_path2
    test_add_relative_path
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    test_add_relative_path
  end

  def test_add_path_with_copy_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=copy"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
  end

  def test_add_path_with_copy_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=copy"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_copy_mode2
    test_add_path_with_copy_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    test_add_path_with_copy_mode
  end

  def test_add_path_with_move_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"])
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=move"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tmp_dir, "AFNetworking")
  end

  def test_add_path_with_move_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=move"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_move_mode2
    test_add_path_with_move_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"])
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=move"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
    assert_contains_file(@store_dir, "AFNetworking")
    assert_contains_file(@tmp_dir, "AFNetworking") # No remove, use cache.
  end

  def test_add_path_with_worktree_mode
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "4eaec5b", "--mode=worktree"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[commit: 4eaec5b586]"])
    assert_not_contains_file(@store_dir, "AFNetworking")
  end

  def test_add_path_with_worktree_mode_keep_changes
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"]) unless File.directory?("#{@tmp_dir}/AFNetworking")
    rm!("#{@tmp_dir}/AFNetworking/CHANGELOG.md")
    mbox!(["add", "#{@tmp_dir}/AFNetworking", "4eaec5b", "--mode=worktree"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[commit: 4eaec5b586]"])
    assert_not_contains_file(@store_dir, "AFNetworking")
    assert_not_contains_file(@tests_dir + "/AFNetworking", "CHANGELOG.md")
  end

  def test_add_path_with_worktree_mode2
    test_add_path_with_worktree_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    # Again
    test_add_path_with_worktree_mode
  end

  def test_add_path_with_worktree_mode_branch_checkouted
    cp!(["-r", "#{@cache_dir}/AFNetworking", "#{@tmp_dir}/"])
    mbox(["add", "#{@tmp_dir}/AFNetworking", "master", "--mode=worktree"], 
      code: 254, 
      stderr: /The branch `master` already checkout at/,
      stdout: /\[Feature\]: .*FreeMode.*[\n\s]+It is empty!/)
    assert_not_contains_file(@store_dir, "AFNetworking")
    assert_repos_is_empty("FreeMode")
    assert_not_contains_file(@tests_dir, "AFNetworking")
  end

  ##################################################################
  def test_add_http_url_then_add_name
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_http_url_then_add_git_url
    test_add_http_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    test_add_git_url
  end

  def test_add_git_url_then_add_name
    test_add_git_url
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_path_then_add_name
    test_add_path_with_copy_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    mbox!(["add", "AFNetworking", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_add_worktree_then_add_name
    test_add_path_with_worktree_mode
    assert_remove_repo("AFNetworking")
    assert_repos_is_empty("FreeMode")
    mbox(["add", "AFNetworking", "master"], code: 254)
    assert_repos_is_empty("FreeMode")
  end
end