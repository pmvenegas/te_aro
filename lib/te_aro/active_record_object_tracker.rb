# frozen_string_literal: true

module TeAro
  class ActiveRecordObjectTracker
    attr_reader :targets, :results

    def initialize(targets = TeAro::Observer::DEFAULT_TARGETS)
      @targets = targets
      @start_called = false
      @stop_called = false

      @results = {}
    end

    def start
      raise('#start has already been called') if @start_called

      @marshaled_objects_before = current_objects.map { |o| marshal(o) }
      @start_called = true
      @started_at = DateTime.now
    end

    def stop
      raise('#start must be called before #stop') unless @start_called
      raise('#stop has already been called') if @stop_called

      @objects_after = current_objects
      @stop_called = true

      record_changes
    end

    def log_results(logger)
      raise('#start and #stop must be called to obtain results') unless @stop_called

      change_counts = @results[:change_counts]

      logger.info('Observed objects:')

      if change_counts.empty?
        logger.info("\t(No changes)")
        return
      end

      change_counts.each do |class_name, delta|
        next if delta.zero?

        logger.info("\t#{class_name}: #{delta}")
      end

      new_objects = @results[:new]
      created_objects = @results[:created]
      changed_objects = @results[:changed]
      object_updates = @results[:object_updates]
      updated_objects = @results[:updated]
      deleted_objects = @results[:deleted]

      logger.info('New objects:') unless new_objects.empty?
      new_objects.each do |object|
        log_object_id(logger, object)
        log_object_attributes(logger, object)
      end

      logger.info('Created objects:') unless created_objects.empty?
      created_objects.each do |object|
        log_object_id(logger, object)
        log_object_attributes(logger, object)
      end

      logger.info('Objects with unsaved changes:') unless changed_objects.empty?
      changed_objects.each do |object|
        log_object_id(logger, object)
        object.changes.each do |var_name, (old_value, new_value)|
          logger.info("\t\t#{var_name}: #{value_or_nil(old_value)} -> #{value_or_nil(new_value)}")
        end
      end

      if !updated_objects.empty? || !object_updates.empty?
        logger.info('Updated objects:')

        object_updates.each do |old, new|
          log_object_id(logger, old)
          old.attributes.each do |attr_name, old_value|
            new_value = new[attr_name]
            logger.info("\t\t#{attr_name}: #{value_or_nil(old_value)} -> #{value_or_nil(new_value)}") unless attr_equal?(
              old_value, new_value
            )
          end
        end

        updated_objects.each do |object|
          log_object_id(logger, object)
        end
      end

      logger.info('Deleted objects:') unless deleted_objects.empty?
      deleted_objects.each do |object|
        log_object_id(logger, object)
      end
    end

    private

    def log_object_id(logger, object)
      message = "\t#{object.class.name}"
      message << " (id=#{object.id})" if object.id
      logger.info(message)
    end

    def log_object_attributes(logger, object)
      object.attributes.reject { |_k, v| v.nil? }.each do |k, v|
        logger.info("\t\t#{k}: #{value_or_nil(v)}")
      end
    end

    def value_or_nil(value)
      value.nil? ? 'nil' : value
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
      a.instance_of?(b.class) && a.attributes.all? { |k, v| attr_equal?(v, b[k]) }
    end

    def same_record?(a, b)
      a.instance_of?(b.class) && a.id == b.id
    end

    def record_changes
      @objects_before = @marshaled_objects_before.map { |o| unmarshal(o) }
      before_count = object_counts_by_class(@objects_before)
      after_count = object_counts_by_class(@objects_after)
      change_counts = object_count_delta(before_count, after_count).reject { |_class_name, delta| delta.zero? }

      @results[:objects_before] = @objects_before
      @results[:objects_after] = @objects_after
      @results[:change_counts] = change_counts

      new_objects = []
      created_objects = []
      changed_objects = []
      object_updates = []
      updated_objects = []
      deleted_objects = []

      # Only inspect objects touched within tracked window
      final_objects = @objects_after.select do |a|
        @objects_before.none? do |b|
          ar_equal?(a, b)
        end
      end

      final_objects.each do |object|
        if object.destroyed?
          deleted_objects << object
        elsif object.new_record?
          new_objects << object
        elsif object.changed?
          changed_objects << object
        elsif object.persisted?
          original = @objects_before.find do |old_object|
            same_record?(old_object, object)
          end

          if original
            # If persisted object was already known at the start of
            # tracking, we can report details of changes made to it
            object_updates << [original, object] unless ar_equal?(original, object)
          elsif object.respond_to?(:created_at) && object.created_at > @started_at
            # Otherwise, report creation/update
            created_objects << object
          elsif object.respond_to?(:updated_at) && object.updated_at > @started_at
            updated_objects << object
          end
        end
      end

      @results[:new] = new_objects
      @results[:created] = created_objects
      @results[:changed] = changed_objects
      @results[:object_updates] = object_updates
      @results[:updated] = updated_objects
      @results[:deleted] = deleted_objects
    end

    def current_objects
      @targets.each_with_object([]) do |target, arr|
        ObjectSpace.each_object(target) do |object|
          arr << object
        end
      end
    end

    def object_counts_by_class(objects)
      counts = objects.group_by { |object| object.class.name }
      counts.each { |k, v| counts[k] = v.count }
    end

    def object_count_delta(before, after)
      deltas = {}
      after.each_key do |k|
        deltas[k] = after[k] - (before[k] || 0)
      end
      before.each_key do |k|
        deltas[k] = -before[k] unless deltas.include?(k)
      end
      deltas
    end

    def ar_to_hash(object)
      object.as_json.merge('class_name' => object.class.to_s)
    end

    def marshal(object)
      Marshal.dump({ klass: object.class, attributes: object.attributes })
    end

    def unmarshal(string)
      hash = Marshal.load(string)
      hash[:klass].new(hash[:attributes])
    end
  end
end
