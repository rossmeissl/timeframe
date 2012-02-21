class Timeframe
  module Iso8601
    # Internal use.
    #
    # Parses a duration like 'P1Y2M4DT3H4M2S'
    class Duration < ::Struct.new(:date_part, :time_part)
      def seconds
        (y*31_556_926 + m*2_629_743.83 + d*86_400 + h*3_600 + minutes*60 + s).ceil
      end
      private
      def y;        @y       ||= parse(date_part, :Y); end
      def m;        @m       ||= parse(date_part, :M); end
      def d;        @d       ||= parse(date_part, :D); end
      def h;        @h       ||= parse(time_part, :H); end
      def minutes;  @minutes ||= parse(time_part, :M); end
      def s;        @s       ||= parse(time_part, :S); end
      def parse(part, indicator)
        if part =~ /(\d+)#{indicator.to_s}/
          $1.to_f
        else
          0
        end
      end
    end

    # Internal use.
    class Side
      # We add one day because so that it can be excluded per timeframe's conventions.
      EXCLUDED_LAST_DAY = 86_400
      attr_reader :date_part, :time_part
      def to_time(counterpart)
        if date_part.start_with?('P')
          counterpart.resolve_time(self) + resolve_offset + EXCLUDED_LAST_DAY
        else
          resolve_time counterpart
        end
      end
    end
    
    # Internal use.
    #
    # The "A" side of "A/B"
    class A < Side
      def initialize(raw)
        raw = raw.upcase
        @date_part, @time_part = raw.split('T')
        @time_part ||= ''
      end
      def resolve_time(*)
        Time.parse [date_part, time_part].join('T')
      end
      # When A is a period, it counts as a negative offset to B.
      def resolve_offset
        0.0 - Duration.new(date_part, time_part).seconds
      end
    end
    
    # Internal use.
    #
    # The "B" side of "A/B"
    class B < Side
      def initialize(raw)
        raw = raw.upcase
        if raw.include?(':') and not raw.include?('T')
          # it's just a shorthand for time
          @date_part = ''
          @time_part = raw
        else
          @date_part, @time_part = raw.split('T')
          @time_part ||= ''
        end
      end
      # When shorthand is used, we need to peek at our counterpart (A) in order to steal letters
      # Shorthand can only be used on the B side, and only in <start>/<end> format.
      def resolve_time(counterpart)
        filled_in_date_part = unless date_part.count('-') == 2
          counterpart.date_part[0..(0-date_part.length-1)] + date_part
        else
          date_part
        end
        filled_in_time_part = if time_part.count(':') < 2
          counterpart.time_part[0..(0-time_part.length-1)] + time_part
        else
          time_part
        end
        Time.parse [filled_in_date_part, filled_in_time_part].join('T')
      end
      def resolve_offset
        Duration.new(date_part, time_part).seconds
      end
    end
  end
end
