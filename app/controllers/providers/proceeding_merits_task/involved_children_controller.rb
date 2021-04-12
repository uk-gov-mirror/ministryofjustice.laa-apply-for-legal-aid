module Providers
  module ProceedingMeritsTask
    class InvolvedChildrenController < ProviderBaseController
      def show
        involved_children
      end

      def update
        involved_children.each { |child| update_record(child[:id], child[:name]) }
        go_forward
      end

      private

      def user_selected?(name)
        params[name] == 'true'
      end

      def child_already_added?(id)
        involved_children.detect { |child| child[:id] == id }[:is_checked]
      end

      def involved_children
        @involved_children ||= legal_aid_application.involved_children.map do |child|
          { id: child.id, name: child.full_name, is_checked: children_ids.any?(child.id) }
        end
      end

      def update_record(id, name)
        if user_selected? name
          create_record id unless child_already_added? id
        elsif child_already_added? id
          delete_record id
        end
      end

      def create_record(id)
        application_proceeding_type
          .application_proceeding_type_involved_children
          .create!(involved_child_id: id)
      end

      def delete_record(id)
        application_proceeding_type
          .application_proceeding_type_involved_children
          .find_by(involved_child_id: id).destroy!
      end

      def application_proceeding_type
        @application_proceeding_type ||= legal_aid_application
                                         .application_proceeding_types
                                         .find(params[:proceeding_merits_task_id])
      end

      def children_ids
        @children_ids ||= application_proceeding_type.involved_children.map(&:id)
      end
    end
  end
end