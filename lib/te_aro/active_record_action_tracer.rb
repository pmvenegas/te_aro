require 'te_aro/action_tracer'

module TeAro
  class ActiveRecordActionTracer < ActionTracer
    DEFAULT_WHITELIST = %w(gems ruby marginalia)

    def initialize(targets=TeAro::Observer::DEFAULT_TARGETS, whitelist: DEFAULT_WHITELIST, blacklist: [])
      super(targets, whitelist: whitelist, blacklist: blacklist)
    end

    private

    def call_hook(tracepoint)
      @ar_hook_observables ||= []
      registered_methods = [:create, :create!, :save, :save!]

      return unless tracepoint.path.match('active_record')

      event, path, line, method_id, classname, object_id, depth, object = destructure(tracepoint)
      return unless is_a_target?(object) && registered_methods.include?(method_id)

      calls << (call = [event, path, line, method_id, classname, object_id, depth])
      @ar_hook_observables << [object, call]
    end
  end
end
