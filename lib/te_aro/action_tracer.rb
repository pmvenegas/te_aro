module TeAro
  class ActionTracer
    attr_reader :accumulator, :calls

    def initialize(targets, whitelist: [], blacklist: [])
      @targets = targets
      @whitelist = whitelist
      @blacklist = blacklist
    end

    def register_whitelist(patterns)
      @whitelist.concat(patterns)
    end

    def register_blacklist(patterns)
      @blacklist.concat(patterns)
    end

    def start
      @calls = []
      @accumulator = { initial: {}, current: {} }

      @tracepoint = TracePoint.new(:call, :return) do |trace|
        call_hook(trace)
      end

      @tracepoint.enable
    end

    def stop
      @tracepoint.disable
    end

    def log_results(logger)
      calls.each do |event, file, _, id, classname, object_id, depth|
        sigil = event == :call ? '->' : '<-'
        logger.info "#{'.'*depth}#{sigil}#{classname}:#{object_id}:#{id} from #{file}"
      end

      initials = accumulator[:initial]
      currents = accumulator[:current]

      initials.keys.each do |object_id|
        if currents[object_id].present?
          if initials[object_id] != currents[object_id]
            logger.info "CHANGE: #{object_id} ======"
            logger.info initials[object_id]
            logger.info "------ ------ ------ ------"
            logger.info currents[object_id]
            logger.info "====== ====== ====== ======"
          end
        end
      end
    end

    private

    def call_hook(tracepoint)
      file_p =  -> (path) {
        @whitelist.any? { |entry| path.match(entry)} || @blacklist.none? { |entry| path.match(entry) }
      }

      return unless file_p.call(tracepoint.path)

      event, path, line, method_id, classname, object_id, depth, object = destructure(tracepoint)

      calls << [event, path, line, method_id, classname, object_id, depth]
      annotate(@accumulator, object)
    end

    def is_a_target?(object)
      @targets.any? { |target| object.is_a? target }
    end

    def destructure(tracepoint)
      event     = tracepoint.event
      path      = tracepoint.path
      line      = tracepoint.lineno
      method_id = tracepoint.method_id
      classname = tracepoint.defined_class.name

      object = tracepoint.self
      object_id = object.object_id
      depth = caller.size

      [event, path, line, method_id, classname, object_id, depth, object]
    end

    def annotate(accumulator, object)
      return unless object && is_a_target?(object)

      if accumulator[:initial][object.object_id]
        accumulator[:current][object.object_id] = object.attributes.to_yaml
      else
        accumulator[:initial][object.object_id] = object.attributes.to_yaml
      end
    end
  end
end
