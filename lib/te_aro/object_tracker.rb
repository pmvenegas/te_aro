module TeAro
  class ObjectTracker
    def initialize(logger)
      @logger = logger
      @before_called = false
      @after_called = false
    end

    def before
      raise(StandardError, "'before' has already been called") if @before_called
      @before_count = active_record_object_counts
      @ar_before = active_record_objects
      @before_called = true
    end

    def after
      raise(StandardError, "'before' must be called before 'after'") unless @before_called
      raise(StandardError, "'after' has already been called") if @after_called
      @after_count = active_record_object_counts
      @ar_after = active_record_objects
      @after_called = true

      process_changes
    end

    def print_changes
      @logger.info "Object Count Changes:"
      @change_counts.each do |klass_name, delta|
        next if delta == 0
        @logger.info "\t#{klass_name}: #{'+' if delta > 0}#{delta}"
      end

      @logger.info "New ActiveRecord objects:" if @new_instances.size > 0
      @new_instances.each do |obj|
        @logger.info "\t#{obj.class.name} (id=#{obj.id})"
        obj.attributes.reject { |k,v| v.nil? }.each do |key, value|
          value = "nil" if value.nil?
          @logger.info "\t\t#{key}: #{value}"
        end
      end

      @logger.info "Changed ActiveRecord objects:" if @new_instances.size > 0
      @changed_instances.each do |obj|
        @logger.info "\t#{obj.class.name} (id=#{obj.id})"
        obj.changes.each do |var_name, (old_val, new_val)|
          old_val = "nil" if old_val.nil?
          @logger.info "\t\t#{var_name}: #{old_val} -> #{new_val}"
        end
      end
    end

    private

    def process_changes
      @change_counts = object_count_delta(@before_count, @after_count).reject {|klass_name, delta| delta == 0 }
      @new_instances = []
      @changed_instances = []

      @ar_after.each do |obj|
        if obj.changed?
          @changed_instances << obj
        elsif !@ar_before.include?(obj)
          @new_instances << obj
        end
      end
    end

    def active_record_objects
      ObjectSpace.each_object(ActiveRecord::Base).each_with_object(Set.new) do |obj, set|
        set.add(obj)
      end
    end

    def active_record_object_counts
      counts = active_record_objects.group_by { |obj| obj.class.name }
      counts.each { |k, v| counts[k] = v.count }
    end

    def object_count_delta(before, after)
      deltas = {}
      after.keys.each do |k|
        delta = after[k] - (before[k] || [])
        deltas[k] = delta
      end
      before.keys.each do |key|
        deltas[k] = -before[key] if !deltas.include?(key)
      end
      deltas
    end
  end
end