module TeAro
  class ObjectTracker
    attr_accessor :ar_before, :ar_after, :changes_persisted

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
          @logger.info "\t\t#{key}: #{value_or_nil(value)}"
        end
      end

      # Might still be useful later; commenting out for now
      # @logger.info "Changed ActiveRecord objects:" if @changed_instances.size > 0
      # @changed_instances.each do |obj|
      #   @logger.info "\t#{obj.class.name} (id=#{obj.id})"
      #   obj.changes.each do |var_name, (old_val, new_val)|
      #     old_val = "nil" if old_val.nil?
      #     @logger.info "\t\t#{var_name}: #{old_val} -> #{new_val}"
      #   end
      # end

      @logger.info "Changed and persisted ActiveRecord objects:" if @changes_persisted.size > 0
      @changes_persisted.each do |old, new|
        @logger.info "\t#{old.class.name} (id=#{old.id})"
        old.attributes.each do |var_name, old_val|
          new_val = new[var_name]
          @logger.info "\t\t#{var_name}: #{value_or_nil(old_val)} -> #{value_or_nil(new_val)}" if !attr_equal?(old_val, new_val)
        end
      end
    end

    def value_or_nil(value)
      value.nil? ? "nil" : value
    end

    # practical Time comparison
    def time_equal?(a, b)
      a.to_i == b.to_i
    end

    def attr_equal?(a, b)
      if a.is_a? Time
        time_equal?(a, b)
      else
        a == b
      end
    end

    def ar_equal?(a, b)
      a.class == b.class && a.attributes.all? { |k, v| attr_equal?(v, b[k]) }
    end

    private

    def process_changes
      @change_counts = object_count_delta(@before_count, @after_count).reject {|klass_name, delta| delta == 0 }
      @new_instances = []
      @changed_instances = []

      @changes_persisted = @ar_before.map do |obj|
        if obj.persisted?
          reloaded = obj.class.find(obj.id)
          [obj, reloaded] if !ar_equal?(obj, reloaded)
        end
      end.compact

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
        delta = after[k] - (before[k] || 0)
        deltas[k] = delta
      end
      before.keys.each do |key|
        deltas[k] = -before[key] if !deltas.include?(key)
      end
      deltas
    end
  end
end
