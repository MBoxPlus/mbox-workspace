require 'mbox-workspace-tests'

class FeatureImport < MBoxWorkspaceTests
  executable :git
  executable :rm

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
          "url":"git@github.com:AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode", ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_import_to_free_append_repo
    mbox!(["add", "git@github.com:dijkst/ObjCCommandLine.git", "master"])
    assert_repo("FreeMode", ["ObjCCommandLine", "git@github.com:dijkst/ObjCCommandLine.git", "[master]"])

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
          "url":"git@github.com:AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repos("FreeMode", 
      [
        ["ObjCCommandLine", "git@github.com:dijkst/ObjCCommandLine.git", "[master]"],
        ["AFNetworking", "git@github.com:AFNetworking/AFNetworking.git", "[master]"]
      ]
    )
  end

  def test_import_to_feature
    json = %{
    {
      "name":"test_import",
      "repos":[
        {
          "last_branch":"master",
          "last_type":"branch",
          "target_branch": "master",
          "url":"git@github.com:dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "git@github.com:dijkst/ObjCCommandLine.git", "master"])
  end
end
