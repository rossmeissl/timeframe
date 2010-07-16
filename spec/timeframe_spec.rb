require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'date'

describe Timeframe do
  describe 'initialization' do
    it 'should create a timeframe using date strings' do
      tf = Timeframe.new('2008-02-14', '2008-05-10')
      tf.from.should == Date.parse('2008-02-14')
      tf.to.should == Date.parse('2008-05-10')
    end
    it 'should create a timeframe using date objects' do
      start = Date.parse('2008-02-14')
      finish = Date.parse('2008-05-10')
      tf = Timeframe.new(start, finish)
      tf.from.should == start
      tf.to.should == finish
    end
    it "should accept months" do
      timeframe = Timeframe.new(:month => 1)
      timeframe.from.should == Date.today.change(:month => 1, :day => 1)
      timeframe.to.should == Date.today.change(:month => 2, :day => 1)
    end
    it "should accept month names" do
      timeframe = Timeframe.new(:month => 'february')
      timeframe.from.should == Date.today.change(:month => 2, :day => 1)
      timeframe.to.should == Date.today.change(:month => 3, :day => 1)
    end
    it "should accept years" do
      timeframe = Timeframe.new(:year => 2004)
      timeframe.from.should == Date.new(2004, 1, 1)
      timeframe.to.should == Date.new(2005, 1, 1)
    end
    it "should accept years and months" do
      timeframe = Timeframe.new(:year => 2005, :month => 5)
      timeframe.from.should == Date.new(2005, 5, 1)
      timeframe.to.should == Date.new(2005, 6, 1)
    end
    it "should not accept just one date argument" do
      lambda {
        Timeframe.new Date.new(2007, 2, 1)
      }.should raise_error(ArgumentError, /supply/)
    end
    it "should not accept end date that is earlier than start date" do
      lambda {
        timeframe = Timeframe.new Date.new(2008, 1, 1), Date.new(2007, 1, 1)
      }.should raise_error(ArgumentError, /earlier/)
    end
    it "should not accept timeframes that cross year boundaries" do
      lambda {
        timeframe = Timeframe.new Date.new(2007, 1, 1), Date.new(2008, 1, 2)
      }.should raise_error(ArgumentError, /cross/)
    end
    it "should optionally accept timeframes that cross year boundaries" do
      lambda {
        timeframe = Timeframe.new Date.new(2007, 1, 1), Date.new(2008, 1, 2), :skip_year_boundary_crossing_check => true
      }.should_not raise_error
    end
  end

  describe '#inspect' do
    it 'should return the time frame in readable text' do
      start = Date.parse('2008-02-14')
      finish = Date.parse('2008-05-10')
      tf = Timeframe.new(start, finish)
      tf.inspect.should =~ /<Timeframe\(-?\d+\) 86 days starting 2008-02-14 ending 2008-05-10>/
    end
  end

  describe '.constrained_new' do
    let(:start) { Date.parse('2008-02-14') }
    let(:finish) { Date.parse('2008-05-10') }
    let(:constraint_start) { Date.parse('2008-01-01') }
    let(:constraint_finish) { Date.parse('2008-12-01') }
    let(:constraint) { Timeframe.new(constraint_start, constraint_finish) }

    it "should allow for constrained creation" do
      constraint = Timeframe.new :year => 2008
      may = Timeframe.new Date.new(2008,5,1), Date.new(2008,6,1)
      january = Timeframe.new Date.new(2008,1,1), Date.new(2008,2,1)
      Timeframe.constrained_new(may.from, may.to, constraint).should == may
      Timeframe.constrained_new(Date.new(2007,1,1), Date.new(2010,1,1), constraint).should == constraint
      Timeframe.constrained_new(Date.new(2007,11,1), Date.new(2008,2,1), constraint).should == january
    end
    it 'should return a timeframe spanning start and end date if within constraint' do
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.should == start
      tf.to.should == finish
    end
    it 'should return a timeframe spanning constraint start and end date if outside constraint' do
      constraint = Timeframe.new(start, finish)
      tf = Timeframe.constrained_new(constraint_start, constraint_finish, constraint)
      tf.from.should == start
      tf.to.should == finish
    end
    it 'should return a timeframe starting at constraint start' do
      start = Date.parse('2008-01-01')
      constraint_start = Date.parse('2008-01-14')
      constraint = Timeframe.new(constraint_start, constraint_finish)
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.should == constraint_start
      tf.to.should == finish
    end
    it 'should return a timeframe ending at constraint end' do
      constraint_finish = Date.parse('2008-04-14')
      constraint = Timeframe.new(constraint_start, constraint_finish)
      tf = Timeframe.constrained_new(start, finish, constraint)
      tf.from.should == start
      tf.to.should == constraint_finish
    end
    it "should return a 0-length timeframe when constraining a timeframe by a disjoint timeframe" do
      constraint = Timeframe.new :year => 2010
      timeframe = Timeframe.constrained_new(
        Date.new(2009,1,1), Date.new(2010,1,1), constraint)
      timeframe.days.should == 0
    end
  end

  describe '.this_year' do
    it "should return the current year" do
      Timeframe.this_year.should == Timeframe.new(:year => Time.now.year)
    end
  end

  describe '#days' do
    it "should return them number of days included" do
      #TODO: make these separate "it" blocks, per best practices
      Timeframe.new(Date.new(2007, 1, 1), Date.new(2008, 1, 1)).days.should == 365
      Timeframe.new(Date.new(2008, 1, 1), Date.new(2009, 1, 1)).days.should == 366 #leap year
      Timeframe.new(Date.new(2007, 11, 1), Date.new(2007, 12, 1)).days.should == 30
      Timeframe.new(Date.new(2007, 11, 1), Date.new(2008, 1, 1)).days.should == 61
      Timeframe.new(Date.new(2007, 2, 1), Date.new(2007, 3, 1)).days.should == 28
      Timeframe.new(Date.new(2008, 2, 1), Date.new(2008, 3, 1)).days.should == 29
      Timeframe.new(Date.new(2008, 2, 1), Date.new(2008, 2, 1)).days.should == 0
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
        timeframe.include?(date).should == true
      end
      [
        Date.new(2008, 1, 1),
        Date.new(2007, 2, 1),
        Date.new(2008, 3, 1)
      ].each do |date|
        timeframe.include?(date).should == false
      end
    end
  end

  describe '#==' do
    it "should be able to know if it's equal to another Timeframe object" do
      Timeframe.new(:year => 2007).should == Timeframe.new(:year => 2007)
      Timeframe.new(:year => 2004, :month => 1).should == Timeframe.new(:year => 2004, :month => 1)
    end
    
    it "should hash equal hash values when the timeframe is equal" do
      Timeframe.new(:year => 2007).hash.should == Timeframe.new(:year => 2007).hash
      Timeframe.new(:year => 2004, :month => 1).hash.should == Timeframe.new(:year => 2004, :month => 1).hash
    end
  end

  describe '#months' do
    it "should return an array of month-long subtimeframes" do
      Timeframe.new(:year => 2009).months.length.should == 12
    end
    it "should not return an array of month-long subtimeframes if provided an inappropriate range" do
      lambda { 
        Timeframe.new(Date.new(2009, 3, 2), Date.new(2009, 3, 5)).months
      }.should raise_error(ArgumentError, /whole/)
      lambda {
        Timeframe.new(Date.new(2009, 1, 1), Date.new(2012, 1, 1), :skip_year_boundary_crossing_check => true).months
      }.should raise_error(ArgumentError, /dangerous during/)
    end
  end

  describe '#year' do
    it "should return the relevant year of a timeframe" do
      Timeframe.new(Date.new(2009, 2, 1), Date.new(2009, 4, 1)).year.should == Timeframe.new(:year => 2009)
    end
    it "should not return the relevant year of a timeframe if provided an inappropriate range" do
      lambda {
        Timeframe.new(Date.new(2009, 1, 1), Date.new(2012, 1, 1), :skip_year_boundary_crossing_check => true).year
      }.should raise_error(ArgumentError, /dangerous during/)
    end
  end

  describe '#&' do
    it "should return its intersection with another timeframe" do
      #TODO: make these separate "it" blocks, per best practices
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 6)).should be_nil
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 5)).should be_nil
      (Timeframe.new(:month => 4) & Timeframe.new(:month => 4)).should == Timeframe.new(:month => 4)
      (Timeframe.new(:year => Time.now.year) & Timeframe.new(:month => 4)).should == Timeframe.new(:month => 4)
      (Timeframe.new(Date.new(2009, 2, 1), Date.new(2009, 6, 1)) & Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 8, 1))).should == Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 6, 1))
    end
  end

  describe '#/' do
    it "should return a fraction of another timeframe" do 
      (Timeframe.new(:month => 4, :year => 2009) / Timeframe.new(:year => 2009)).should == (30.0 / 365.0)
    end
  end

  describe '#gaps_left_by' do
    it "should be able to ascertain gaps left by a list of other Timeframes" do
      Timeframe.new(:year => 2009).gaps_left_by(
        Timeframe.new(:year => 2009, :month => 3),
        Timeframe.new(:year => 2009, :month => 5),
        Timeframe.new(Date.new(2009, 8, 1), Date.new(2009, 11, 1)),
        Timeframe.new(Date.new(2009, 9, 1), Date.new(2009, 10, 1))
      ).should == 
        [ Timeframe.new(Date.new(2009, 1, 1), Date.new(2009, 3, 1)),
          Timeframe.new(Date.new(2009, 4, 1), Date.new(2009, 5, 1)),
          Timeframe.new(Date.new(2009, 6, 1), Date.new(2009, 8, 1)),
          Timeframe.new(Date.new(2009, 11, 1), Date.new(2010, 1, 1)) ]
    end
  end

  describe '#covered_by?' do
    it "should be able to ascertain gaps left by a list of other Timeframes" do
      Timeframe.new(:year => 2009).covered_by?(
        Timeframe.new(:month => 1, :year => 2009), 
        Timeframe.new(Date.new(2009, 2, 1), Date.new(2010, 1, 1))
      ).should be_true
    end
  end

  describe '#last_year' do
    it "should return its predecessor in a previous year" do
      Timeframe.this_year.last_year.should ==
        Timeframe.new(Date.new(Date.today.year - 1, 1, 1), Date.new(Date.today.year, 1, 1))
    end
  end
  
  describe 'Timeframe:class#interval' do
    it 'should parse ISO 8601 interval format' do
      Timeframe.interval('2009-01-01/2010-01-01').should == Timeframe.new(:year => 2009)
    end
    it 'should understand its own #to_param' do
      t = Timeframe.new(:year => 2009)
      Timeframe.interval(t.to_param).should == t
    end
  end
  
  describe '#to_json' do
    it 'should generate JSON' do
      Timeframe.new(:year => 2009).to_json.should == "{\"from\":\"2009-01-01\",\"to\":\"2010-01-01\"}"
    end
  end
  
  describe '#to_param' do
    it 'should generate a URL-friendly parameter' do
      Timeframe.new(:year => 2009).to_param.should == "2009-01-01/2010-01-01"
    end
  end
  
  describe '#to_s' do
    it 'should not only look at month numbers when describing multi-year timeframes' do
      Timeframe.multiyear(Date.parse('2008-01-01'), Date.parse('2010-01-01')).to_s.should == "the period from 01 January to 31 December 2009"
    end
  end
end
