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
          "url":"https://github.com/AFNetworking/AFNetworking.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("FreeMode", ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"])
  end

  def test_import_to_free_append_repo
    mbox!(["add", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
    assert_repo("FreeMode", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"])

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
        ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "[master]"],
        ["AFNetworking", "https://github.com/AFNetworking/AFNetworking.git", "[master]"]
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
          "url":"https://github.com/dijkst/ObjCCommandLine.git"
        }
      ]
    }
    }
    mbox!(["feature", "import", json])
    assert_repo("test_import", ["ObjCCommandLine", "https://github.com/dijkst/ObjCCommandLine.git", "master"])
  end
end
