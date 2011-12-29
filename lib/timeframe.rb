require 'date'
require 'active_support/version'
%w{
  active_support/core_ext/hash
  active_support/core_ext/array/extract_options
  active_support/core_ext/string/conversions
  active_support/core_ext/date/conversions
  active_support/core_ext/integer/time
  active_support/core_ext/numeric/time
  active_support/json
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

require 'timeframe/core_ext/array'
# Encapsulates a timeframe between two dates. The dates provided to the class are always until the last date. That means
# that the last date is excluded.
#
#   # from 2007-10-01 00:00:00.000 to 2007-10-31 23:59:59.999
#   Timeframe.new(Date(2007,10,1), Date(2007,11,1))
#   # and holds 31 days
#   Timeframe.new(Date(2007,10,1), Date(2007,11,1)).days #=> 31
class Timeframe
  attr_accessor :from, :to

  # Creates a new instance of Timeframe. You can either pass a start and end Date or a Hash with named arguments,
  # with the following options:
  #
  #   <tt>:month</tt>: Start date becomes the first day of this month, and the end date becomes the first day of
  #   the next month. If no <tt>:year</tt> is specified, the current year is used.
  #   <tt>:year</tt>: Start date becomes the first day of this year, and the end date becomes the first day of the
  #   next year.
  #
  # By default, Timeframe.new will die if the resulting Timeframe would cross year boundaries. This can be overridden
  # by setting the <tt>:skip_year_boundary_crossing_check</tt> option.
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
      from = Date.new(year, month, 1)
      to   = from.next_month
    elsif year = options[:year]
      from = Date.new(year, 1, 1)
      to   = Date.new(year+1, 1, 1)
    end

    from = args.shift.to_date if from.nil? and args.any?
    to = args.shift.to_date if to.nil? and args.any?

    raise ArgumentError, "Please supply a start and end date, `#{args.map(&:inspect).to_sentence}' is not enough" if from.nil? or to.nil?
    raise ArgumentError, "Start date #{from} should be earlier than end date #{to}" if from > to
    raise ArgumentError, 'Timeframes that cross year boundaries are dangerous' unless options[:skip_year_boundary_crossing_check] or from.year == to.yesterday.year or from == to

    @from, @to = from, to
  end

  def inspect # :nodoc:
    "<Timeframe(#{object_id}) #{days} days starting #{from} ending #{to}>"
  end

  # The number of days in the timeframe
  #
  #   Timeframe.new(Date.new(2007, 11, 1), Date.new(2007, 12, 1)).days #=> 30
  #   Timeframe.new(:month => 1).days #=> 31
  #   Timeframe.new(:year => 2004).days #=> 366
  def days
    (to - from).to_i
  end

  # Returns true when a Date or other Timeframe is included in this Timeframe
  def include?(obj)
    # puts "checking to see if #{date} is between #{from} and #{to}" if Emitter::DEBUG
    case obj
    when Date
      (from...to).include?(obj)
    when Time
      # (from...to).include?(obj.to_date)
      raise "this wasn't previously supported, but it could be"
    when Timeframe
      from <= obj.from and to >= obj.to
    end
  end

  # Returns true when the parameter Timeframe is properly included in the Timeframe
  def proper_include?(other_timeframe)
    raise ArgumentError, 'Proper inclusion only makes sense when testing other Timeframes' unless other_timeframe.is_a? Timeframe
    (from < other_timeframe.from) and (to > other_timeframe.to)
  end

  # Returns true when this timeframe is equal to the other timeframe
  def ==(other)
    # puts "checking to see if #{self} is equal to #{other}" if Emitter::DEBUG
    return false unless other.is_a?(Timeframe)
    from == other.from and to == other.to
  end
  alias :eql? :==

  # Calculates a hash value for the Timeframe, used for equality checking and Hash lookups.
  #--
  # This needs to be an integer or else it won't use #eql?
  def hash
    from.hash + to.hash
  end

  # Returns an array of month-long subtimeframes
  #--
  # TODO: rename to month_subtimeframes
  def months
    raise ArgumentError, "Please only provide whole-month timeframes to Timeframe#months" unless from.day == 1 and to.day == 1
    raise ArgumentError, 'Timeframes that cross year boundaries are dangerous during Timeframe#months' unless from.year == to.yesterday.year
    year = from.year # therefore this only works in the from year
    (from.month..to.yesterday.month).map { |m| Timeframe.new :month => m, :year => year }
  end

  # Returns the relevant year as a Timeframe
  def year
    raise ArgumentError, 'Timeframes that cross year boundaries are dangerous during Timeframe#year' unless from.year == to.yesterday.year
    Timeframe.new :year => from.year
  end

  # Divides a Timeframe into component parts, each no more than a month long.
  #--
  # multiyear safe
  def month_subtimeframes
    (from.year..to.yesterday.year).map do |year|
      (1..12).map do |month|
        Timeframe.new(:year => year, :month => month) & self
      end
    end.flatten.compact
  end

  # Like #month_subtimeframes, but will discard partial months
  # multiyear safe
  def full_month_subtimeframes
    month_subtimeframes.map { |st| Timeframe.new(:year => st.from.year, :month => st.from.month) }
  end

  # Divides a Timeframe into component parts, each no more than a year long.
  #--
  # multiyear safe
  def year_subtimeframes
    (from.year..to.yesterday.year).map do |year|
      Timeframe.new(:year => year) & self
    end
  end

  # Like #year_subtimeframes, but will discard partial years
  #--
  # multiyear safe
  def full_year_subtimeframes
    (from.year..to.yesterday.year).map do |year|
      Timeframe.new :year => year
    end
  end

  # Crop a Timeframe to end no later than the provided date.
  #--
  # multiyear safe
  def ending_no_later_than(date)
    if to < date
      self
    elsif from >= date
      nil
    else
      Timeframe.multiyear from, date
    end
  end

  # Returns a timeframe representing the intersection of the given timeframes
  def &(other_timeframe)
    this_timeframe = self
    if other_timeframe == this_timeframe
      this_timeframe
    elsif this_timeframe.from > other_timeframe.from and this_timeframe.to < other_timeframe.to
      this_timeframe
    elsif other_timeframe.from > this_timeframe.from and other_timeframe.to < this_timeframe.to
      other_timeframe
    elsif this_timeframe.from >= other_timeframe.to or this_timeframe.to <= other_timeframe.from
      nil
    else
      Timeframe.new [this_timeframe.from, other_timeframe.from].max, [this_timeframe.to, other_timeframe.to].min, :skip_year_boundary_crossing_check => true
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
    self.class.new [from, container.from].max, [to, container.to].min, :skip_year_boundary_crossing_check => true
  end

  # Returns an array of Timeframes representing the gaps left in the Timeframe after removing all given Timeframes
  def gaps_left_by(*timeframes)
    # remove extraneous timeframes
    timeframes.reject! { |t| t.to <= from }
    timeframes.reject! { |t| t.from >= to }

    # crop timeframes
    timeframes.map! { |t| t.crop self }

    # remove proper subtimeframes
    timeframes.reject! { |t| timeframes.detect { |u| u.proper_include? t } }

    # escape
    return [self] if  timeframes.empty?

    timeframes.sort! { |x, y| x.from <=> y.from }

    a = [ from ] + timeframes.collect(&:to)
    b = timeframes.collect(&:from) + [ to ]

    a.zip(b).map do |gap|
      Timeframe.new(*gap, :skip_year_boundary_crossing_check => true) if gap[1] > gap[0]
    end.compact
  end

  # Returns true if the union of the given Timeframes includes the Timeframe
  def covered_by?(*timeframes)
    gaps_left_by(*timeframes).empty?
  end

  # Returns the same Timeframe, only a year earlier
  def last_year
    self.class.new((from - 1.year), (to - 1.year))
  end

  def as_json(*)
    to_param
  end

  # overriding this so that as_json is not used
  def to_json(*)
    to_param
  end

  # An ISO 8601 "time interval" like YYYY-MM-DD/YYYY-MM-DD
  def to_param
    "#{from}/#{to}"
  end

  # The String representation is equivalent to its ISO 8601 form
  def to_s
    to_param
  end

  class << self
    def make_dates(from, to) # :nodoc:
      return from.to_date, to.to_date
    end

    # Shortcut method to return the Timeframe representing the current year (as defined by Time.now)
    def this_year
      new :year => Time.now.year
    end

    # Construct a new Timeframe, but constrain it by another
    def constrained_new(from, to, constraint)
      from, to = make_dates from, to
      raise ArgumentError, 'Constraint must be a Timeframe' unless constraint.is_a? Timeframe
      raise ArgumentError, "Start date #{from} should be earlier than end date #{to}" if from > to
      if to <= constraint.from or from >= constraint.to
        new constraint.from, constraint.from
      elsif from.year == to.yesterday.year
        new(from, to) & constraint
      elsif from.year < constraint.from.year and constraint.from.year < to.yesterday.year
        constraint
      else
        new [constraint.from, from].max, [constraint.to, to].min
      end
    end

    # Shortcut for #new that automatically skips year boundary crossing checks
    def multiyear(from, to)
      from, to = make_dates from, to
      new from, to, :skip_year_boundary_crossing_check => true
    end

    # Create a multiyear timeframe +/- number of years around today
    def mid(number)
      from = Time.zone.today - number.years
      to = Time.zone.today + number.years
      multiyear from, to
    end

    # Construct a new Timeframe by parsing an ISO 8601 time interval string
    # http://en.wikipedia.org/wiki/ISO_8601#Time_intervals
    def interval(str)
      raise ArgumentError, 'Intervals should be specified as a string' unless str.is_a? String
      raise ArgumentError, 'Intervals should be specified according to ISO 8601, method 1, eliding times' unless str =~ /^\d\d\d\d-\d\d-\d\d\/\d\d\d\d-\d\d-\d\d$/
      multiyear *str.split('/')
    end
    alias :from_json :interval
  end
end
