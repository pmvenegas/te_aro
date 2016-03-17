module TeAro
  class ActionTrace
    attr_reader :accumulator, :calls

    def initialize(logger)
      @blacklist = []
      @whitelist = []
      @logger = logger
    end

    def register_whitelist(patterns)
      @whitelist.concat(patterns)
    end

    def register_blacklist(patterns)
      @blacklist.concat(patterns)
    end

    def self.for_active_record(logger)
      instance = new(logger)
      instance.register_blacklist(%w(gems ruby marginalia))
      instance
    end

    def start
      @calls = []
      @accumulator = { initial: {}, current: {} }
      @file_p =  -> (path) {
        @whitelist.any? { |entry| path.match(entry)} || @blacklist.none? { |entry| path.match(entry) }
      }

      @tracepoint = TracePoint.new(:call, :return) do |trace|
        extract(trace, @calls) if @file_p.call(trace.path)
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

    def extract(tracepoint, calls)
      event         = tracepoint.event
      path          = tracepoint.path
      line          = tracepoint.lineno
      method_id     = tracepoint.method_id
      defined_class = tracepoint.defined_class

      subject = tracepoint.self
      object_id = subject.object_id

      depth = caller.size
      calls << [event, path, line, method_id, defined_class, object_id, depth]
      annotate(@accumulator, subject)
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