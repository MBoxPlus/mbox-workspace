require_relative 'MBoxWorkspaceTests'

class MboxRemove < MBoxWorkspaceTests
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
        @productName = "AFNetworking"
        @repoAddress = "https://github.com/AFNetworking/AFNetworking.git"
        @targetBranch = "master"

        @productTwo = "ObjCCommandLine"
        @repoTwo = "https://github.com/dijkst/ObjCCommandLine.git"

        git!(["-C", @cache_dir, "clone", @repoAddress])
        git!(["-C", @cache_dir, "clone", @repoTwo])
    end
    
  
    def setup
      super
      mbox!(["add", "#{@cache_dir}/#{@productName}", @targetBranch, "--mode=copy"])
    end

    #1
    def test_remove_from_FreeMode
        assert_repo("FreeMode", [@productName, @repoAddress, @targetBranch])
        mbox!(["remove", @productName])
        assert_repos_is_empty("FreeMode")
    end

    #2
    def test_remove_from_feature
        mbox!(["feature", "start", "newFeature"])
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", @productName])
        assert_repos_is_empty("newFeature")
    end


    #3
    def test_remove_invalid_repo_from_feature
        mbox!(["feature", "start", "newFeature"])
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])

        mbox(["remove", "non-exist-repo"],code: MBoxErrorCode::USER)
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    end


    #4
    def test_remove_all_repos_from_feature
        mbox!(["feature", "start", "newFeature"])
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", "--all"])
        assert_repos_is_empty("newFeature")
    end

    #5
    def test_remove_repo_from_feature_twice
        test_remove_from_feature()
        mbox!(["add", @productName, @targetBranch])
        test_remove_from_feature()


        mbox!(["add", @productName, @targetBranch])
        mbox!(["add", "#{@cache_dir}/#{@productTwo}", @targetBranch, "--mode=copy"])


        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        assert_repo("newFeature", [@productTwo, @repoTwo, "[feature/newFeature]", "->", @targetBranch])

        mbox!(["remove", @productName])
        mbox!(["remove", @productTwo])
        assert_repos_is_empty("newFeature")

    end

    #6
    def test_remove_repo_with_uncommitted_data
        testfileName = setup_feature_with_uncommitted_data("newFeature")
        mbox(["remove", @productName],code: MBoxErrorCode::USER)
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    end

    #7
    def test_remove_repo_with_unmergered_committed_data_from_feature
        testfileName = setup_feature_with_committed_data("newFeature")
        mbox(["remove", @productName],code: MBoxErrorCode::USER)
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
    end

    #8
    def test_remove_repo_from_feature_force

        mbox!(["feature", "start", "newFeature"])
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", @productName,"--force"])
        assert_repos_is_empty("newFeature")
    end

    #9
    def test_remove_repo_with_uncommitted_data_force
        testfileName = setup_feature_with_uncommitted_data("newFeature")
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", @productName,"--force"])
        assert_repos_is_empty("newFeature")

    end

    #10
    def test_remove_repo_with_unmergered_committed_data_from_feature_force
        testfileName = setup_feature_with_committed_data("newFeature")
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", @productName,"--force"])
        assert_repos_is_empty("newFeature")

    end

    #11
    def test_remove_repo_from_feature_include_cache
        mbox!(["feature", "start", "newFeature"])
        assert_repo("newFeature", [@productName, @repoAddress, "[feature/newFeature]", "->", @targetBranch])
        mbox!(["remove", @productName,"--include-repo"])
        assert_repos_is_empty("newFeature")
        assert_not_contains_file(@store_dir, @productName)
    end

    

end
