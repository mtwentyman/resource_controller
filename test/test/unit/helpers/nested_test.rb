require File.dirname(__FILE__)+'/../../test_helper'

class PostsControllerMock
  include ResourceController::Helpers
  extend ResourceController::Accessors
  class_reader_writer :belongs_to
end

class CommentsControllerMock
  include ResourceController::Helpers
  extend ResourceController::Accessors
  class_reader_writer :belongs_to
  belongs_to :post
end

class Helpers::NestedTest < Test::Unit::TestCase
  def setup
    @controller = PostsControllerMock.new

    @params = stub :[] => "1"
    @controller.stubs(:params).returns(@params)
    
    @request = stub :path => ""
    @controller.stubs(:request).returns(@request)        

    @object = Post.new
    Post.stubs(:find).with("1").returns(@object)
    
    @collection = mock()
    Post.stubs(:find).with(:all).returns(@collection)
  end
  
  context "parent type helper" do
    setup do
      CommentsControllerMock.class_eval do
        belongs_to :post
      end
      @comments_controller = CommentsControllerMock.new
      @comment_params = stub()
      @comment_params.stubs(:[]).with(:post_id).returns 2
      
      @comments_controller.stubs(:params).returns(@comment_params)
    end

    should "get the params for the current parent" do
      assert_equal [:post], @comments_controller.send(:parent_types)
    end
    
    context "with multiple possible parents" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to :post, :product
        end
        
        @comment_params = stub()
        @comment_params.stubs(:[]).with(:product_id).returns 5
        @comment_params.stubs(:[]).with(:post_id).returns nil
        @comments_controller.stubs(:params).returns(@comment_params)
      end

      should "get the params for whatever models are available" do
        assert_equal [:product], @comments_controller.send(:parent_types)
      end
      
      teardown do
        CommentsControllerMock.class_eval do
          belongs_to :post
        end
      end
    end
    
    context "with multiple possible parents including deeply nested parent sets" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to :post, [:product, :tag]
        end
        
        @comment_params = stub()
        @comment_params.stubs(:[]).with(:post_id).returns nil
        @comment_params.stubs(:[]).with(:product_id).returns 5
        @comment_params.stubs(:[]).with(:tag_id).returns 5
        @comments_controller.stubs(:params).returns(@comment_params)
      end

      should "choose the matching set" do
        assert_equal [:product, :tag], @comments_controller.send(:parent_types)
      end
    end
    
    context "with no possible parent" do      
      should "return nil" do
        assert @controller.send(:parent_types).nil?, @controller.send(:parent_types).inspect
      end
    end
  end
  
  context "parent param helper" do
    setup { @controller.params.expects(:[]).with(:post_id) }
    should "add _id to the type passed and pass that as the key to params" do
      @controller.send :parent_param, :post
    end
  end
  
  context "parent objects" do
    context "with multiple possible parents" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to [:product, :tag, :something_else], :post
        end

        @comments_controller = CommentsControllerMock.new

        @comment_params = stub()
        @comment_params.stubs(:[]).with(:post_id).returns 1
        @comment_params.stubs(:[]).with(:product_id).returns 5
        @comment_params.stubs(:[]).with(:tag_id).returns 5
        @comment_params.stubs(:[]).with(:something_else_id).returns 5

        @comments_controller.stubs(:params).returns(@comment_params)

        @something_else_mock = mock
        @something_elses_assoc_proxy = mock
        @something_elses_assoc_proxy.expects(:find).with(5).returns(@something_else_mock)
        @tag_mock    = mock
        @tag_mock.stubs(:something_elses => @something_elses_assoc_proxy)
        @tags_assoc_proxy = mock
        @tags_assoc_proxy.expects(:find).with(5).returns(@tag_mock)
        @product     = stub(:tags => @tags_assoc_proxy)
        Product.expects(:find).with(5).returns(@product)
      end

      should "get the parents" do
        assert_equal [[:product, @product], [:tag, @tag_mock], [:something_else, @something_else_mock]], @comments_controller.send(:parent_objects)
      end
    end
    
    
    
    context "with a single possible parent" do
      setup do
        CommentsControllerMock.class_eval do
          belongs_to :product
        end

        @comments_controller = CommentsControllerMock.new

        @comment_params = stub()
        @comment_params.stubs(:[]).with(:product_id).returns 5

        @comments_controller.stubs(:params).returns(@comment_params)

        Product.expects(:find).with(5).returns(@product = mock)
      end

      should "fetch the single object" do
        assert_equal [[:product, @product]], @comments_controller.send(:parent_objects)
      end
    end
  end
  
  context "end of association chain when there are parents" do
    setup do
      @comments_controller = CommentsControllerMock.new
      @comment_params = stub()
      @comment_params.stubs(:[]).with(:post_id).returns 2
      @request = stub :path => ""
      @comments_controller.stubs(:request).returns(@request)          
      @comments_controller.stubs(:params).returns(@comment_params)
      @post = Post.new
      Post.stubs(:find).with(2).returns @post
    end

    should "acquire the association proxy for the current model from the last parent object" do
      assert_equal '', @controller.send(:end_of_association_chain)
    end
  end
end