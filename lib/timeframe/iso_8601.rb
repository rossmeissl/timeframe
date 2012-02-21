class Timeframe
  module Iso8601
    # Internal use.
    #
    # Parses a duration like 'P1Y2M4DT3H4M2S'
    class Duration
      def initialize(raw)
        @date_part, @time_part = raw.upcase.split('T')
        @time_part ||= ''
      end
      def seconds
        (y*31_556_926 + m*2_629_743.83 + d*86_400 + h*3_600 + minutes*60 + s).ceil
      end
      private
      def y;        @y       ||= parse(@date_part, :Y); end
      def m;        @m       ||= parse(@date_part, :M); end
      def d;        @d       ||= parse(@date_part, :D); end
      def h;        @h       ||= parse(@time_part, :H); end
      def minutes;  @minutes ||= parse(@time_part, :M); end
      def s;        @s       ||= parse(@time_part, :S); end
      def parse(part, indicator)
        if part =~ /(\d+)#{indicator.to_s}/
          $1.to_f
        else
          0
        end
      end
    end

    # Internal use.
    class Part < ::Struct.new(:raw)
      EXCLUDED_LAST_DAY = 86_400
      
      def as_duration
        Duration.new raw
      end
      def as_time
        ::Time.parse raw
      end
      def resolve(other)
        if raw.start_with?('P')
          other.as_time + as_offset + EXCLUDED_LAST_DAY
        else
          as_time
        end
      end
    end
    
    # Internal use.
    class A < Part
      def as_offset
        0.0 - as_duration.seconds
      end
    end
    
    # Internal use.
    class B < Part
      def as_offset
        as_duration.seconds
      end
    end
  end
end
