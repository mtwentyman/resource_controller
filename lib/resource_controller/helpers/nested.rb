# Nested and Polymorphic Resource Helpers
#
module ResourceController
  module Helpers
    module Nested
      protected    
        # Returns the relevant association proxy of the parent. (i.e. /posts/1/comments # => @post.comments)
        #
        def parent_association
          @parent_association ||= parent_object.send(model_name.to_s.pluralize.to_sym)
        end
    
        # Returns the type of the current parent
        #
        def parent_type
          @parent_type ||= parent_type_from_params || parent_type_from_request
        end
    
        def parent_types
          @parent_types ||= [*belongs_to].reject(&:nil?).
                              map { |parent_type| [*parent_type] }.
                                detect { |parent_type| parent_type.all? { |parent| !parent_param(parent).nil? } }
        end
    
        # Returns the type of the current parent extracted from params
        #    
        def parent_type_from_params
          [*belongs_to].find { |parent| !params["#{parent}_id".to_sym].nil? }
        end
    
        # Returns the type of the current parent extracted form a request path
        #    
        def parent_type_from_request
          [*belongs_to].find { |parent| request.path.split('/').include? parent.to_s }
        end
    
        # Returns true/false based on whether or not a parent is present.
        #
        def parent?
          !parent_type.nil?
        end
        # def parent?
        #   !parent_types.nil?
        # end
    
        # Returns true/false based on whether or not a parent is a singleton.
        #    
        def parent_singleton?
          !parent_type_from_request.nil? && parent_type_from_params.nil?
        end
    
        # Returns the current parent param, if there is a parent. (i.e. params[:post_id])
        def parent_param(type=nil)
          params["#{type.nil? ? parent_type : type}_id".to_sym]
        end
    
        # Like the model method, but for a parent relationship.
        # 
        def parent_model
          parent_type.to_s.camelize.constantize
        end
    
        def parent_model_for(type)
          type.to_s.classify.constantize
        end

        # Returns the current parent object if a parent object is present.
        #
        def parent_object
          parent? && !parent_singleton? ? parent_model.find(parent_param) : nil
        end

        def parent_objects
          @parent_objects ||= returning [] do |parent_objects|
            unless parent_types.length == 1
              parent_types.inject do |last, next_type|
                parent_objects << [last, last = parent_model_for(last).find(parent_param(last))] if last.is_a? Symbol
                
                next_entry     = [next_type, last.send(next_type.to_s.pluralize).find(parent_param(next_type))]
                parent_objects << next_entry
                next_entry.last
              end
            else
              parent_objects << [parent_types.last, parent_model_for(parent_types.last).find(parent_param(parent_types.last))] if parent_types.last.is_a? Symbol
            end
          end
        end
        
        # If there is a parent, returns the relevant association proxy.  Otherwise returns model.
        #
        def end_of_association_chain
          parent? ? parent_association : model
          # parent? ? parent_objects.last.last.send(model_name.to_s.pluralize.intern) : model #ADDED_BY_MIKE
        end
    end
  end
end
