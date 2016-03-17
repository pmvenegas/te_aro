module ActiveRecord
  module Observer
    class ActionTrace
      attr_reader :accumulator, :calls

      def initialize
        @blacklist = %w(gems ruby marginalia)
      end

      def start
        @calls = []
        @accumulator = { initial: {}, current: {} }

        set_trace_func proc { |event, file, line, id, binding, classname|
          is_call = event == 'call'
          is_ret  = event == 'return'
          subject = binding.try!(:eval, 'self')
          object_id = binding.try!(:eval, 'self.object_id')

          file_p =  -> (path) { @blacklist.none? { |entry| path.match(entry) } }

          if is_call && file_p.call(file)
            depth = caller.size
            @calls << [event, file, line, id, classname, object_id, depth]
            annotate(@accumulator, subject)
          elsif is_ret && file_p.call(file)
            depth = caller.size
            @calls << [event, file, line, id, classname, object_id, depth]
            annotate(@accumulator, subject)
          end
        }
      end

      def stop
        set_trace_func nil
      end

      def print_trace
        calls.each do |event, file, _, id, classname, object_id, depth|
          sigil = event == 'call' ? '->' : '<-'
          puts "#{'.'*depth}#{sigil}#{classname}:#{object_id}:#{id} from #{file}"
        end
        nil
      end

      def print_changes
        initials = accumulator[:initial]
        currents = accumulator[:current]

        initials.keys.each do |object_id|
          if currents[object_id].present?
            if initials[object_id] != currents[object_id]
              puts "CHANGE: #{object_id} ======"
              puts initials[object_id]
              puts "------ ------ ------ ------"
              puts currents[object_id]
              puts "====== ====== ====== ======"
            end
          end
        end
        nil
      end

      private

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
end