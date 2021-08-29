require 'mbox-dev/mbox-tests'

class MBoxWorkspaceTests < MBoxTests
  def output_verbose_log
    Dir[@tests_dir + "/.mbox/logs/*/CLI/*.verbose.log"].sort.each do |path|
      puts File.read(path)
      puts ""
    end
  end

  def should_setup_workspace
    true
  end

  def setup_workspace_group
    nil
  end

  def setup_workspace_plugins
    []
  end

  def setup
    super
    return unless should_setup_workspace
    cmd = ["init"]
    cmd << setup_workspace_group unless setup_workspace_group.nil?
    cmd.concat setup_workspace_plugins.map { |name| ["--plugin", name] }
    mbox!(cmd)

    @store_dir = @tests_dir + "/.mbox/repos"
  end

  def assert_repos_is_empty(feature)
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+It is empty!/)
  end

  def assert_repo(feature, repo)
    regex = repo ? repo.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") : "It is empty!"
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+#{regex}/)
    assert_contains_file(@tests_dir, repo.first) if repo
  end

  def assert_repos(feature, repos)
    regex = repos.map { |lines| lines.map { |item| ".*#{Regexp.quote(item)}.*" }.join("\s+") }.join("[\n\s]+")
    mbox!("status", stdout: /\[Feature\]: .*#{Regexp.quote(feature)}.*[\n\s]+#{regex}/)
    assert_contains_file(@tests_dir, repos.map { |repo| repo.first })
  end
end