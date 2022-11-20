module TeAro
  class ActionTracer
    attr_reader :accumulator, :calls

    def initialize(logger)
      @blacklist = []
      @whitelist = []
      @logger = logger
      @hooks = [method(:standard_hook)]
    end

    def register_whitelist(patterns)
      @whitelist.concat(patterns)
    end

    def register_blacklist(patterns)
      @blacklist.concat(patterns)
    end

    def register_hook(hook)
      @hooks << hook
    end

    def self.for_active_record(logger)
      instance = new(logger)
      instance.register_blacklist(%w(gems ruby marginalia))
      instance.register_hook(instance.method(:ar_hook))
      instance
    end

    def start
      @calls = []
      @accumulator = { initial: {}, current: {} }

      @tracepoint = TracePoint.new(:call, :return) do |trace|
        @hooks.each do |hook|
          hook.call(trace)
        end
      end

      @tracepoint.enable
    end

    def stop
      @tracepoint.disable
    end

    def print_trace
      calls.each do |event, file, _, id, classname, object_id, depth|
        sigil = event == :call ? '->' : '<-'
        @logger.info "#{'.'*depth}#{sigil}#{classname}:#{object_id}:#{id} from #{file}"
      end
      nil
    end

    def print_changes
      initials = accumulator[:initial]
      currents = accumulator[:current]

      initials.keys.each do |object_id|
        if currents[object_id].present?
          if initials[object_id] != currents[object_id]
            @logger.info "CHANGE: #{object_id} ======"
            @logger.info initials[object_id]
            @logger.info "------ ------ ------ ------"
            @logger.info currents[object_id]
            @logger.info "====== ====== ====== ======"
          end
        end
      end
      nil
    end

    private

    def standard_hook(tracepoint)
      file_p =  -> (path) {
        @whitelist.any? { |entry| path.match(entry)} || @blacklist.none? { |entry| path.match(entry) }
      }

      return unless file_p.call(tracepoint.path)

      event, path, line, method_id, classname, object_id, depth, subject = destructure(tracepoint)

      calls << [event, path, line, method_id, classname, object_id, depth]
      annotate(@accumulator, subject)
    end

    def ar_hook(tracepoint)
      @ar_hook_observables ||= []
      registered_methods = [:create, :create!, :save, :save!]

      return unless tracepoint.path.match('active_record')

      event, path, line, method_id, classname, object_id, depth, subject = destructure(tracepoint)
      return unless subject.is_a?(ActiveRecord::Base) && registered_methods.include?(method_id)

      calls << (call = [event, path, line, method_id, classname, object_id, depth])
      @ar_hook_observables << [subject, call]
    end

    def destructure(tracepoint)
      event     = tracepoint.event
      path      = tracepoint.path
      line      = tracepoint.lineno
      method_id = tracepoint.method_id
      classname = tracepoint.defined_class.name

      subject = tracepoint.self
      object_id = subject.object_id
      depth = caller.size

      [event, path, line, method_id, classname, object_id, depth, subject]
    end

    def annotate(accumulator, object)
      return unless object && object.is_a?(ActiveRecord::Base)

      if accumulator[:initial][object.object_id]
        accumulator[:current][object.object_id] = object.attributes.to_yaml
      else
        accumulator[:initial][object.object_id] = object.attributes.to_yaml
      end
    end
  end
end
