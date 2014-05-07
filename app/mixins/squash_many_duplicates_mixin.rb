module SquashManyDuplicatesMixin
  def self.included(mixee)
    mixee.class_eval do
      def duplicates
        @type = params[:type]
        begin
          instance_variable_model = self.controller_name
          instance_variable_that_we_need_to_set = "@grouped_#{instance_variable_model}".to_sym
          my_model = self.controller_name.classify.constantize
          instance_variable_set(instance_variable_that_we_need_to_set, my_model.find_duplicates_by_type(@type))
          #@grouped_events = my_model.find_duplicates_by_type(@type)
        rescue ArgumentError => e
          instance_variable_set(instance_variable_that_we_need_to_set, {})
          #@grouped_events = {}
          flash[:failure] = "#{e}"
        end

        @page_title = "Duplicate #{instance_variable_model.titleize} Squasher"

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :xml => self.instance_variable_get(instance_variable_that_we_need_to_set) }
        end
      end

      # POST /venues/squash_multiple_duplicates
      def squash_many_duplicates
        # Derive model class from controller name
        model_class = self.controller_name.singularize.titleize.constantize

        master_id = params[:master_id].try(:to_i)
        duplicate_ids = params.keys.grep(/^duplicate_id_\d+$/){|t| params[t].to_i}
        singular = model_class.name.singularize.downcase
        plural = model_class.name.pluralize.downcase

        if master_id.nil?
          flash[:failure] = "A master #{singular} must be selected."
        elsif duplicate_ids.empty?
          flash[:failure] = "At least one duplicate #{singular} must be selected."
        elsif duplicate_ids.include?(master_id)
          flash[:failure] = "The master #{singular} could not be squashed into itself."
        else
          squashed = model_class.squash(:master => master_id, :duplicates => duplicate_ids)

          if squashed.size > 0
            message = "Squashed duplicate #{plural} #{squashed.map {|obj| obj.title}.inspect} into master #{master_id}."
            flash[:success] = flash[:success].nil? ? message : flash[:success] + message
          else
            message = "No duplicate #{plural} were squashed."
            flash[:failure] = flash[:failure].nil? ? message : flash[:failure] + message
          end
        end

        redirect_to :action => "duplicates", :type => params[:type]
      end

    end
  end
end
