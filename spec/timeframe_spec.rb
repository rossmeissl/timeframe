require File.expand_path('../spec_helper', __FILE__)

describe Timeframe do
  describe 'initialization' do
    it 'should create a timeframe using date strings' do
      tf = Timeframe.new('2008-02-14', '2008-05-10')
      tf.from.must_equal Date.parse('2008-02-14')
      tf.to.must_equal Date.parse('2008-05-10')
    end
    it 'should create a timeframe using date objects' do
      start = Date.parse('2008-02-14')
      finish = Date.parse('2008-05-10')
      tf = Timeframe.new(start, finish)
      tf.from.must_equal start
      tf.to.must_equal finish
    end
    it "should accept months" do
      timeframe = Timeframe.new(:month => 1)
      timeframe.from.must_equal Date.today.change(:month => 1, :day => 1)
      timeframe.to.must_equal Date.today.change(:month => 2, :day => 1)
    end
    it "should accept month names" do
      timeframe = Timeframe.new(:month => 'february')
      timeframe.from.must_equal Date.today.change(:month => 2, :day => 1)
      timeframe.to.must_equal Date.today.change(:month => 3, :day => 1)
    end
    it "should accept years" do
      timeframe = Timeframe.new(:year => 2004)
      timeframe.from.must_equal Date.new(2004, 1, 1)
      timeframe.to.must_equal Date.new(2005, 1, 1)
    end
    it "should accept years and months" do
      timeframe = Timeframe.new(:year => 2005, :month => 5)
      timeframe.from.must_equal Date.new(2005, 5, 1)
      timeframe.to.must_equal Date.new(2005, 6, 1)
    end
    it "should not accept just one date argument" do
      lambda {
        Timeframe.new Date.new(2007, 2, 1)
      }.must_raise(ArgumentError, /supply/)
    end
    it "should not accept end date that is earlier than start date" do
      lambda {
        timeframe = Timeframe.new Date.new(2008, 1, 1), Date.new(2007, 1, 1)
      }.must_raise(ArgumentError, /earlier/)
    end
    it "should always accept timeframes that cross year boundaries" do
      timeframe = Timeframe.new Date.new(2007, 1, 1), Date.new(2008, 1, 2)
      timeframe.start_date.must_equal Date.new(2007, 1, 1)
    end
  end

  describe '#inspect' do
    it 'should return the time frame in readable text' do
      start = Date.parse('2008-02-14')
      finish = Date.parse('2008-05-10')
      tf = Timeframe.new(start, finish)
      tf.inspect.must_match %r{<Timeframe\(-?\d+\) 86 days starting 2008-02-14 ending 2008-05-10>}
    end
  end

  describe :constrained_new do
    let(:start) { Date.parse('2008-02-14') }
    let(:finish) { Date.parse('2008-05-10') }
    let(:constraint_start) { Date.parse('2008-01-01') }
    let(:constraint_finish) { Date.parse('2008-12-01') }
    let(:constraint) { Timeframe.new(constraint_start, constraint_finish) }

    it "should allow for constrained creation" do
      constraint = Timeframe.new :year => 2008
      may = Timeframe.new Date.new(2008,5,1), Date.new(2008,6,1)
      january = Timeframe.new Date.new(2008,1,1), Date.new(2008,2,1)
      Timeframe.constrained_new(may.from, may.to, constraint).must_equal may
      Timeframe.constrained_new(Date.new(2007,1,1), Date.new(2010,1,1), constraint).must_equal constraint
      Timeframe.constrained_new(Date.new(2007,11,1), Date.new(2008,2,1), constraint).must_equal january
    end
    it 'should return a timeframe spanning start and end date if within constraint' do
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.must_equal start
      tf.to.must_equal finish
    end
    it 'should return a timeframe spanning constraint start and end date if outside constraint' do
      constraint = Timeframe.new(start, finish)
      tf = Timeframe.constrained_new(constraint_start, constraint_finish, constraint)
      tf.from.must_equal start
      tf.to.must_equal finish
    end
    it 'should return a timeframe starting at constraint start' do
      start = Date.parse('2008-01-01')
      constraint_start = Date.parse('2008-01-14')
      constraint = Timeframe.new(constraint_start, constraint_finish)
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.must_equal constraint_start
      tf.to.must_equal finish
    end
    it 'should return a timeframe ending at constraint end' do
      constraint_finish = Date.parse('2008-04-14')
      constraint = Timeframe.new(constraint_start, constraint_finish)
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.must_equal start
      tf.to.must_equal constraint_finish
    end
    it "should return a 0-length timeframe when constraining a timeframe by a disjoint timeframe" do
      constraint = Timeframe.new :year => 2010
      timeframe = Timeframe.constrained_new(
        Date.new(2009,1,1), Date.new(2010,1,1), constraint)
      timeframe.days.must_equal 0
    end
  end

  describe :this_year do
    it "should return the current year" do
      Timeframe.this_year.must_equal Timeframe.new(:year => Time.now.year)
    end
  end

  describe '#days' do
    it "should return them number of days included" do
      #TODO: make these separate "it" blocks, per best practices
      Timeframe.new(Date.new(2007, 1, 1), Date.new(2008, 1, 1)).days.must_equal 365
      Timeframe.new(Date.new(2008, 1, 1), Date.new(2009, 1, 1)).days.must_equal 366 #leap year
      Timeframe.new(Date.new(2007, 11, 1), Date.new(2007, 12, 1)).days.must_equal 30
      Timeframe.new(Date.new(2007, 11, 1), Date.new(2008, 1, 1)).days.must_equal 61
      Timeframe.new(Date.new(2007, 2, 1), Date.new(2007, 3, 1)).days.must_equal 28
      Timeframe.new(Date.new(2008, 2, 1), Date.new(2008, 3, 1)).days.must_equal 29
      Timeframe.new(Date.new(2008, 2, 1), Date.new(2008, 2, 1)).days.must_equal 0
    end
  end

  describe '#include?' do
    it "should know if a certain date is included in the Timeframe" do
      #TODO: make these separate "it" blocks, per best practices
      timeframe = Timeframe.new :year => 2008, :month => 2
      [
        Date.new(2008, 2, 1),
        Date.new(2008, 2, 5),
        Date.new(2008, 2, 29)
      ].each do |date|
        timeframe.include?(date).must_equal true
      end
      [
        Date.new(2008, 1, 1),
        Date.new(2007, 2, 1),
        Date.new(2008, 3, 1)
      ].each do |date|
        timeframe.include?(date).must_equal false
      end
    end
  end

  describe '#==' do
    it "should be able to know if it's equal to another Timeframe object" do
      Timeframe.new(:year => 2007).must_equal Timeframe.new(:year => 2007)
      Timeframe.new(:year => 2004, :month => 1).must_equal Timeframe.new(:year => 2004, :month => 1)
    end

    it "should hash equal hash values when the timeframe is equal" do
      Timeframe.new(:year => 2007).hash.must_equal Timeframe.new(:year => 2007).hash
      Timeframe.new(:year => 2004, :month => 1).hash.must_equal Timeframe.new(:year => 2004, :month => 1).hash
    end
  end

  describe '#months' do
    it "should return an array of month-long subtimeframes" do
      Timeframe.new(:year => 2009).months.length.must_equal 12
    end
  end

  describe '#year' do
    it "should return the relevant year of a timeframe" do
      Timeframe.new(Date.new(2009, 2, 1), Date.new(2009, 4, 1)).year.must_equal Timeframe.new(:year => 2009)
    end
    it "should not return the relevant year of a timeframe if provided an inappropriate range" do
      lambda {
        Timeframe.new(Date.new(2009, 1, 1), Date.new(2012, 1, 1)).year
      }.must_raise(ArgumentError, /dangerous during/)
    end
  end

  describe '#&' do
    it "should return its intersection with another timeframe" do
      #TODO: make these separate "it" blocks, per best practices
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 6)).must_be_nil
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 5)).must_be_nil
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 4)).must_equal Timeframe.new(:month => 4)
      (Timeframe.new(:year => Time.now.year) & Timeframe.new(:month => 4)).must_equal Timeframe.new(:month => 4)
      (Timeframe.new(Date.new(2009, 2, 1), Date.new(2009, 6, 1)) & Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 8, 1))).must_equal Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 6, 1))
    end
  end

  describe '#/' do
    it "should return a fraction of another timeframe" do 
      (Timeframe.new(:month => 4, :year => 2009) / Timeframe.new(:year => 2009)).must_equal(30.0 / 365.0)
    end
  end

  describe '#gaps_left_by' do
    it "should be able to ascertain gaps left by a list of other Timeframes" do
      Timeframe.new(:year => 2009).gaps_left_by(
        Timeframe.new(:year => 2009, :month => 3),
        Timeframe.new(:year => 2009, :month => 5),
        Timeframe.new(Date.new(2009, 8, 1), Date.new(2009, 11, 1)),
        Timeframe.new(Date.new(2009, 9, 1), Date.new(2009, 10, 1))
      ).must_equal(
        [ Timeframe.new(Date.new(2009, 1, 1), Date.new(2009, 3, 1)),
          Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 5, 1)),
          Timeframe.new(Date.new(2009, 6, 1), Date.new(2009, 8, 1)),
          Timeframe.new(Date.new(2009, 11, 1), Date.new(2010, 1, 1)) ])
    end
  end

  describe '#covered_by?' do
    it "should be able to ascertain gaps left by a list of other Timeframes" do
      Timeframe.new(:year => 2009).covered_by?(
        Timeframe.new(:month => 1, :year => 2009),
        Timeframe.new(Date.new(2009, 2, 1), Date.new(2010, 1, 1))
      ).must_equal(true)
    end
  end

  describe '#last_year' do
    it "should return its predecessor in a previous year" do
      Timeframe.this_year.last_year.must_equal Timeframe.new(Date.new(Date.today.year - 1, 1, 1), Date.new(Date.today.year, 1, 1))
    end
  end
  
  describe :parse do
    describe 'ISO 8601 <start>/<end>' do
      it 'works without time' do
        Timeframe.parse('2007-03-01/2008-05-11').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
        Timeframe.parse('2007-03-01--2008-05-11').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
      end
      it 'works with time' do
        Timeframe.parse('2007-03-01T13:00:00Z/2008-05-11T15:30:00Z').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
        Timeframe.parse('2007-03-01T13:00:00Z--2008-05-11T15:30:00Z').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
      end
      it 'takes shorthand' do
        Timeframe.parse('2007-11-13/15').must_equal Timeframe.new(Date.new(2007, 11, 13), Date.new(2007, 11, 15)) # "2007-11-13/15", i.e. from any time on 2007-11-13 to any time on 2007-11-15
        Timeframe.parse("2008-02-15/03-14").must_equal Timeframe.new(Date.new(2008, 2, 15), Date.new(2008, 3, 14)) # "2008-02-15/2008-03-14"
        Timeframe.parse("2007-12-14T13:30/15:30").must_equal Timeframe.new(Date.new(2007, 12, 14), Date.new(2007, 12, 14)) # "2007-12-14T13:30/2007-12-14T15:30".. imprecise!
      end
    end

    describe 'ISO 8601 <start>/<duration>' do
      it 'works without time' do
        Timeframe.parse('2007-03-01/P1Y2M10DT2H30M').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
        Timeframe.parse('2007-03-01--P1Y2M10DT2H30M').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
      end
      it 'works with time' do
        Timeframe.parse('2007-03-01T13:00:00Z/P1Y2M10DT2H30M').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
        Timeframe.parse('2007-03-01T13:00:00Z--P1Y2M10DT2H30M').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 5, 11))
      end
    end
    
    # note that 2008 was a leap year
    describe 'ISO 8601 <duration>/<end>' do
      it 'works with leap years' do
        Timeframe.parse('2007-02-28--P1Y').must_equal Timeframe.new(Date.new(2007, 2, 28), Date.new(2008, 2, 29))
        Timeframe.parse('P1Y--2008-02-29').must_equal Timeframe.new(Date.new(2007, 3, 1), Date.new(2008, 2, 29))
      end
      it 'works without time' do
        Timeframe.parse('P1Y2M10DT2H30M/2008-05-11').must_equal Timeframe.new(Date.new(2007, 3, 2), Date.new(2008, 5, 11))
        Timeframe.parse('P1Y2M10DT2H30M--2008-05-11').must_equal Timeframe.new(Date.new(2007, 3, 2), Date.new(2008, 5, 11))
      end
      it 'works with time' do
        Timeframe.parse('P1Y2M10DT2H30M/2008-05-11T15:30:00Z').must_equal Timeframe.new(Date.new(2007, 3, 3), Date.new(2008, 5, 11))
        Timeframe.parse('P1Y2M10DT2H30M--2008-05-11T15:30:00Z').must_equal Timeframe.new(Date.new(2007, 3, 3), Date.new(2008, 5, 11))
      end
    end

    it 'understands plain year' do
      plain_year = 2009
      Timeframe.parse(plain_year).must_equal Timeframe.new(:year => plain_year)
      Timeframe.parse(plain_year.to_s).must_equal Timeframe.new(:year => plain_year)
    end
    it 'understands JSON' do
      json =<<-EOS
      {"startDate":"2009-05-01", "endDate":"2009-06-01"}
EOS
      Timeframe.parse(json).must_equal Timeframe.new(:year => 2009, :month => 5)
    end
    it 'understands a Ruby hash' do
      hsh = { :startDate => '2009-05-01', :endDate => '2009-06-01' }
      Timeframe.parse(hsh).must_equal Timeframe.new(:year => 2009, :month => 5)
      Timeframe.parse(hsh.stringify_keys).must_equal Timeframe.new(:year => 2009, :month => 5)
    end
  end

  describe '#to_json' do
    it 'should generate JSON (test fails on ruby 1.8)' do
      Timeframe.new(:year => 2009).to_json.must_equal %({"startDate":"2009-01-01","endDate":"2010-01-01"})
    end
    it 'understands its own #to_json' do
      t = Timeframe.new(:year => 2009, :month => 5)
      Timeframe.from_json(t.to_json).must_equal t
    end
  end

  describe '#to_param' do
    it 'should generate a URL-friendly parameter' do
      Timeframe.new(:year => 2009).to_param.must_equal "2009-01-01/2010-01-01"
    end
    it 'understands its own #to_param' do
      t = Timeframe.new(:year => 2009, :month => 5)
      Timeframe.parse(t.to_param).must_equal t
    end
  end

  describe '#to_s' do
    it 'should not only look at month numbers when describing multi-year timeframes' do
      Timeframe.new(Date.parse('2008-01-01'), Date.parse('2010-01-01')).to_s.must_equal "2008-01-01/2010-01-01"
    end
  end
  
  describe '#dates' do
    it "should enumerate all dates between start and end" do
      dates = Timeframe.new(:year => 2008).dates
      dates.min.must_equal Date.new(2008,1,1)
      dates.max.must_equal Date.new(2008,12,31)
      dates.uniq.length.must_equal 366
      dates.select { |d| d.month == 2 }.length.must_equal 29
    end
  end
  
  describe '#first_days_of_months' do
    it "should enumerate all the first days of included months" do
      dates = Timeframe.parse('2011-05-01/2012-02-01').first_days_of_months
      dates.must_equal [Date.new(2011,5,1), Date.new(2011,6,1), Date.new(2011,7,1), Date.new(2011,8,1), Date.new(2011,9,1), Date.new(2011,10,1), Date.new(2011,11,1), Date.new(2011,12,1), Date.new(2012,1,1)]
    end
  end

  describe "Array#multiple_timeframes_gaps_left_by" do
    it "should raise error if not a Timeframes are going to be merged" do
      lambda {
        [Timeframe.new(Date.parse('2011-10-10'), Date.parse('2011-10-28'))].multiple_timeframes_gaps_left_by(1,2)
      }.must_raise(ArgumentError, /only use timeframe/)
    end

    it "should properly work with multiple timeframes" do
      t1 = Timeframe.new(Date.parse('2011-10-10'), Date.parse('2011-10-28'))
      t2 = Timeframe.new(Date.parse('2011-11-01'), Date.parse('2011-11-12'))

      t3 = Timeframe.new(Date.parse('2011-10-11'), Date.parse('2011-10-15'))
      t4 = Timeframe.new(Date.parse('2011-11-01'), Date.parse('2011-11-08'))

      [t1, t2].multiple_timeframes_gaps_left_by(t3, t4).must_equal(
      [ Timeframe.new(Date.parse('2011-10-10'), Date.parse('2011-10-11')),
        Timeframe.new(Date.parse('2011-10-15'), Date.parse('2011-10-28')),
        Timeframe.new(Date.parse('2011-11-08'), Date.parse('2011-11-12'))
      ])
    end
  end
end
