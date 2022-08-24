require_relative 'MBoxWorkspaceTests'

class FeatureImport < MBoxWorkspaceTests
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
  def test_import_to_free
    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
  end


  #2
  def test_import_to_free_append_repo
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repos("FreeMode", 
      [
        ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"],
        ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"]
      ]
    )
  end



  #3
  def test_import_to_free_append_the_same_repo
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])

    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
  end



  #4
  def test_import_to_free_append_the_same_repo_with_uncommitted_data
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/AFNetworking")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/AFNetworking","add",testfileName])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)

    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)
  end



  #5
  def test_import_to_free_append_the_same_repo_with_committed_data
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/AFNetworking")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/AFNetworking","add",testfileName])
    git!(["-C","#{@tests_dir}/AFNetworking","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)

    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)
  end


  #6
  def test_import_to_free_append_the_same_repo_with_uncommitted_data_keep_changes
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/AFNetworking")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/AFNetworking","add",testfileName])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)

    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json,"--keep_changes"])
    assert_repo("FreeMode",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)
  end

  #7
  def test_import_to_free_append_the_same_repo_with_committed_data_keep_changes
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/AFNetworking")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/AFNetworking","add",testfileName])
    git!(["-C","#{@tests_dir}/AFNetworking","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)
    json = %{
    { "branch_prefix":"feature/",
      "current_containers":[],
      "name":"",
      "repos":[
        { "full_name":"AFNetworking",
          "last_branch":"master",
          "last_type":"branch",
          "name":"AFNetworking",
          "owner":"AFNetworking",
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json,"--keep_changes"])
    assert_repo("FreeMode",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_contains_file("#{@tests_dir}/AFNetworking", testfileName)
  end


  #8
  def test_import_to_feature_from_FreeMode_when_the_feature_not_exist
    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end

  #9
  def test_import_to_feature_from_other_feature_when_the_feature_not_exist
    mbox!(["feature","start","tempfeature"])
    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end


  #10
  def test_import_to_feature_from_FreeMode_when_a_empty_feature_exist
    mbox!(["feature", "start","test_import","--clear"])
    assert_repos_is_empty("test_import")

    mbox!(["feature", "free"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end

  #11
  def test_import_to_feature_from_feature_when_a_empty_feature_exist
    mbox!(["feature", "start","test_import","--clear"])
    assert_repos_is_empty("test_import")
    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end



  #12
  def test_import_to_feature_from_FreeMode_when_feature_exist_with_repo
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("test_import", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])

    mbox!(["feature", "free"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import",["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
  end




    #13
    def test_import_to_feature_from_FreeMode_when_the_feature_has_the_same_repo_with_uncommitted_data
      mbox!(["feature","free"])

      mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
      assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

      testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
      testfileName = File.basename(testfile.path)
      git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
      assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

      

      json = %{
      {
        "name":"test_import",
        "repos":[
          {
            "last_branch":"master",
            "last_type":"branch",
            "target_branch": "master",
            "url":"https://github.com/dijkst/ObjCCommandLine.git"
          }
        ]
      }
      }
      mbox!(["feature", "import", json])
      assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
      assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
    end

    #14
    def test_import_to_feature_from_FreeMode_when_the_feature_has_the_same_repo_with_committed_data
      mbox!(["feature", "start","test_import"])
      mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
      assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

      testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
      testfileName = File.basename(testfile.path)
      git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
      git!(["-C","#{@tests_dir}/ObjCCommandLine","commit","-m" "\'test feature\'"])
      assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
    
      mbox!(["feature","free"])

      json = %{
      {
        "name":"test_import",
        "repos":[
          {
            "last_branch":"master",
            "last_type":"branch",
            "target_branch": "master",
            "url":"https://github.com/dijkst/ObjCCommandLine.git"
          }
        ]
      }
      }
      mbox!(["feature", "import", json])
      assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
      assert_not_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
    end


  #15
  def test_import_to_feature_from_FreeMode_when_the_feature_has_the_same_repo_with_uncommitted_data_keep_changes
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    mbox!(["feature","free"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--keep-changes"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end



  #16
  def test_import_to_feature_from_FreeMode_when_FreeMode_has_the_same_repo_with_committed_data_keep_changes
    mbox!(["feature","free"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    git!(["-C","#{@tests_dir}/ObjCCommandLine","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--keep-changes"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end



  #17
  def test_import_to_feature_from_feature_when_feature_exist_with_repo
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("test_import", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repos("test_import",[["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"],
      ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"]])
  end





  #18
  def test_import_to_feature_from_feature_when_the_feature_has_the_same_repo_with_uncommitted_data
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end


  #19
  def test_import_to_feature_from_feature_when_the_feature_has_the_same_repo_with_committed_data
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    git!(["-C","#{@tests_dir}/ObjCCommandLine","checkout","master"])

    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    git!(["-C","#{@tests_dir}/ObjCCommandLine","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    git!(["-C","#{@tests_dir}/ObjCCommandLine", "status"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    git!(["-C","#{@tests_dir}/ObjCCommandLine", "status"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end




  #20
  def test_import_to_feature_from_feature_when_the_feature_has_the_same_repo_with_uncommitted_data_keep_changes
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--keep-changes"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end


  #21
  def test_import_to_feature_from_feature_when_the_feature_has_the_same_repo_with_committed_data_keep_changes
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])

    testfile = Tempfile.new("MboxTest", "#{@tests_dir}/ObjCCommandLine")
    testfileName = File.basename(testfile.path)
    git!(["-C","#{@tests_dir}/ObjCCommandLine","add",testfileName])
    git!(["-C","#{@tests_dir}/ObjCCommandLine","commit","-m" "\'test feature\'"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--keep-changes"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_contains_file("#{@tests_dir}/ObjCCommandLine", testfileName)
  end


  #22
  def test_import_to_feature_when_the_feature_not_exist_check_branch_exists
    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--check-branch-exists"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end


  #23
  def test_import_to_feature_when_the_feature_is_empty_check_branch_exists
      mbox!(["feature", "start","test_import", "--clear"])
    assert_repos_is_empty("test_import")
        json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--check-branch-exists"])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end





  #24
  def test_import_to_feature_from_feature_when_feature_exist_with_repo_check_branch_exists
    mbox!(["feature", "start","test_import"])
    mbox!(["add", "https://github.com/AFNetworking/AFNetworking.git", "master"])
    assert_repo("test_import", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])

    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json, "--check-branch-exists"])
    assert_repo("test_import",["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("test_import",["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "master"])
  end





end
