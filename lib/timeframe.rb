require 'date'
require 'multi_json'
require 'active_support/version'
require 'active_support/core_ext' if ActiveSupport::VERSION::MAJOR >= 3

# Encapsulates a timeframe between two dates. The dates provided to the class are always until the last date. That means
# that the last date is excluded.
#
#   # from 2007-10-01 00:00:00.000 to 2007-10-31 23:59:59.999
#   Timeframe.new(Date(2007,10,1), Date(2007,11,1))
#   # and holds 31 days
#   Timeframe.new(Date(2007,10,1), Date(2007,11,1)).days #=> 31
class Timeframe
  class << self    
    # Shortcut method to return the Timeframe representing the current year (as defined by Time.now)
    def this_year
      new :year => Time.now.year
    end
    
    # Construct a new Timeframe, but constrain it by another
    def constrained_new(start_date, end_date, constraint)
      start_date, end_date = make_dates start_date, end_date
      raise ArgumentError, 'Constraint must be a Timeframe' unless constraint.is_a? Timeframe
      raise ArgumentError, "Start date #{start_date} should be earlier than end date #{end_date}" if start_date > end_date
      if end_date <= constraint.start_date or start_date >= constraint.end_date
        new constraint.start_date, constraint.start_date
      elsif start_date.year == end_date.yesterday.year
        new(start_date, end_date) & constraint
      elsif start_date.year < constraint.start_date.year and constraint.start_date.year < end_date.yesterday.year
        constraint
      else
        new [constraint.start_date, start_date].max, [constraint.end_date, end_date].min
      end
    end
    
    # Create a timeframe +/- number of years around today
    def mid(number)
      start_date = Time.now.today - number.years
      end_date = Time.now.today + number.years
      new start_date, end_date
    end
    
    # Construct a new Timeframe by parsing an ISO 8601 time interval string
    # http://en.wikipedia.org/wiki/ISO_8601#Time_intervals
    def from_iso8601(str)
      raise ArgumentError, 'Intervals should be specified according to ISO 8601, method 1, eliding times' unless str =~ /^\d\d\d\d-\d\d-\d\d\/\d\d\d\d-\d\d-\d\d$/
      new *str.split('/')
    end
    
    # Construct a new Timeframe from a hash with keys startDate and endDate    
    def from_hash(hsh)
      hsh = hsh.symbolize_keys
      new hsh[:startDate], hsh[:endDate]
    end
    
    # Construct a new Timeframe from a year.
    def from_year(year)
      new :year => year.to_i
    end
    
    # Automagically parse a Timeframe from either a String or a Hash
    def parse(input)
      case input
      when ::Integer
        from_year input
      when ::Hash
        from_hash input
      when ::String
        str = input.strip
        if str.start_with?('{')
          from_hash ::MultiJson.decode(str)
        elsif input =~ /\A\d\d\d\d\z/
          from_year input
        else
          from_iso8601 str
        end
      else
        raise ::ArgumentError, "Must be String or Hash"
      end
    end
    alias :interval :parse
    alias :from_json :parse
    
    # Deprecated
    def multiyear(*args) # :nodoc:
      new *args
    end

    private
    
    def make_dates(start_date, end_date)
      [start_date.to_date, end_date.to_date]
    end
  end

  attr_reader :start_date
  attr_reader :end_date

  # Creates a new instance of Timeframe. You can either pass a start and end Date or a Hash with named arguments,
  # with the following options:
  #
  #   <tt>:month</tt>: Start date becomes the first day of this month, and the end date becomes the first day of
  #   the next month. If no <tt>:year</tt> is specified, the current year is used.
  #   <tt>:year</tt>: Start date becomes the first day of this year, and the end date becomes the first day of the
  #   next year.
  #
  # Examples:
  #
  #   Timeframe.new Date.new(2007, 2, 1), Date.new(2007, 4, 1) # February and March
  #   Timeframe.new :year => 2004 # The year 2004
  #   Timeframe.new :month => 4 # April
  #   Timeframe.new :year => 2004, :month => 2 # Feburary 2004
  def initialize(*args)
    options = args.extract_options!

    if month = options[:month]
      month = Date.parse(month).month if month.is_a? String
      year = options[:year] || Date.today.year
      start_date = Date.new(year, month, 1)
      end_date   = start_date.next_month
    elsif year = options[:year]
      start_date = Date.new(year, 1, 1)
      end_date   = Date.new(year+1, 1, 1)
    end

    start_date = args.shift.to_date if start_date.nil? and args.any?
    end_date = args.shift.to_date if end_date.nil? and args.any?

    raise ArgumentError, "Please supply a start and end date, `#{args.map(&:inspect).to_sentence}' is not enough" if start_date.nil? or end_date.nil?
    raise ArgumentError, "Start date #{start_date} should be earlier than end date #{end_date}" if start_date > end_date

    @start_date, @end_date = start_date, end_date
  end

  def inspect # :nodoc:
    "<Timeframe(#{object_id}) #{days} days starting #{start_date} ending #{end_date}>"
  end
    
  # The number of days in the timeframe
  #
  #   Timeframe.new(Date.new(2007, 11, 1), Date.new(2007, 12, 1)).days #=> 30
  #   Timeframe.new(:month => 1).days #=> 31
  #   Timeframe.new(:year => 2004).days #=> 366
  def days
    (end_date - start_date).to_i
  end

  # Returns true when a Date or other Timeframe is included in this Timeframe
  def include?(obj)
    # puts "checking to see if #{date} is between #{start_date} and #{end_date}" if Emitter::DEBUG
    case obj
    when Date
      (start_date...end_date).include?(obj)
    when Time
      # (start_date...end_date).include?(obj.to_date)
      raise "this wasn't previously supported, but it could be"
    when Timeframe
      start_date <= obj.start_date and end_date >= obj.end_date
    end
  end

  # Returns true when the parameter Timeframe is properly included in the Timeframe
  def proper_include?(other_timeframe)
    raise ArgumentError, 'Proper inclusion only makes sense when testing other Timeframes' unless other_timeframe.is_a? Timeframe
    (start_date < other_timeframe.start_date) and (end_date > other_timeframe.end_date)
  end

  # Returns true when this timeframe is equal to the other timeframe
  def ==(other)
    # puts "checking to see if #{self} is equal to #{other}" if Emitter::DEBUG
    return false unless other.is_a?(Timeframe)
    start_date == other.start_date and end_date == other.end_date
  end
  alias :eql? :==

  # Calculates a hash value for the Timeframe, used for equality checking and Hash lookups.
  def hash
    start_date.hash + end_date.hash
  end

  # Returns the relevant year as a Timeframe
  def year
    raise ArgumentError, 'Timeframes that cross year boundaries are dangerous during Timeframe#year' unless start_date.year == end_date.yesterday.year
    Timeframe.new :year => start_date.year
  end

  # Returns an Array of month-long Timeframes. Partial months are **not** included by default.
  # http://stackoverflow.com/questions/1724639/iterate-every-month-with-date-objects
  def months
    memo = []
    ptr = start_date
    while ptr <= end_date do
      memo.push(Timeframe.new(:year => ptr.year, :month => ptr.month) & self)
      ptr = ptr >> 1
    end
    memo.flatten.compact
  end

  # Crop a Timeframe to end no later than the provided date.
  def ending_no_later_than(date)
    if end_date < date
      self
    elsif start_date >= date
      nil
    else
      Timeframe.new start_date, date
    end
  end

  # Returns a timeframe representing the intersection of the given timeframes
  def &(other_timeframe)
    this_timeframe = self
    if other_timeframe == this_timeframe
      this_timeframe
    elsif this_timeframe.start_date > other_timeframe.start_date and this_timeframe.end_date < other_timeframe.end_date
      this_timeframe
    elsif other_timeframe.start_date > this_timeframe.start_date and other_timeframe.end_date < this_timeframe.end_date
      other_timeframe
    elsif this_timeframe.start_date >= other_timeframe.end_date or this_timeframe.end_date <= other_timeframe.start_date
      nil
    else
      Timeframe.new [this_timeframe.start_date, other_timeframe.start_date].max, [this_timeframe.end_date, other_timeframe.end_date].min
    end
  end

  # Returns the fraction (as a Float) of another Timeframe that this Timeframe represents
  def /(other_timeframe)
    raise ArgumentError, 'You can only divide a Timeframe by another Timeframe' unless other_timeframe.is_a? Timeframe
    self.days.to_f / other_timeframe.days.to_f
  end

  # Crop a Timeframe by another Timeframe
  def crop(container)
    raise ArgumentError, 'You can only crop a timeframe by another timeframe' unless container.is_a? Timeframe
    self.class.new [start_date, container.start_date].max, [end_date, container.end_date].min
  end

  # Returns an array of Timeframes representing the gaps left in the Timeframe after removing all given Timeframes
  def gaps_left_by(*timeframes)
    # remove extraneous timeframes
    timeframes.reject! { |t| t.end_date <= start_date }
    timeframes.reject! { |t| t.start_date >= end_date }
    
    # crop timeframes
    timeframes.map! { |t| t.crop self }

    # remove proper subtimeframes
    timeframes.reject! { |t| timeframes.detect { |u| u.proper_include? t } }

    # escape
    return [self] if  timeframes.empty?

    timeframes.sort! { |x, y| x.start_date <=> y.start_date }
    
    a = [ start_date ] + timeframes.collect(&:end_date)
    b = timeframes.collect(&:start_date) + [ end_date ]

    a.zip(b).map do |gap|
      Timeframe.new(*gap) if gap[1] > gap[0]
    end.compact
  end

  # Returns true if the union of the given Timeframes includes the Timeframe
  def covered_by?(*timeframes)
    gaps_left_by(*timeframes).empty?
  end

  # Returns the same Timeframe, only a year earlier
  def last_year
    self.class.new((start_date - 1.year), (end_date - 1.year))
  end
  
  def to_json(*)
    %({"startDate":"#{start_date.iso8601}","endDate":"#{end_date.iso8601}"})
  end
  
  def as_json(*)
    { :startDate => start_date.iso8601, :endDate => end_date.iso8601 }
  end
    
  # An ISO 8601 "time interval" like YYYY-MM-DD/YYYY-MM-DD
  def iso8601
    "#{start_date.iso8601}/#{end_date.iso8601}"
  end
  alias :to_s :iso8601
  alias :to_param :iso8601
  
  def dates
    dates = []
    cursor = start_date
    while cursor < end_date
      dates << cursor
      cursor = cursor.succ
    end
    dates
  end
  
  def first_days_of_months
    dates = []
    cursor = start_date.beginning_of_month
    while cursor < end_date
      dates << cursor
      cursor = cursor >> 1
    end
    dates
  end
  
  # Deprecated
  def from # :nodoc:
    @start_date
  end
  
  # Deprecated
  def to # :nodoc:
    @end_date
  end
end
