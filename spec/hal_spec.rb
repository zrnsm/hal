require_relative('../hal')

describe Hal do
  describe '#parse' do
   it 'parses the empty list' do
      subject.parse('()').should == []
   end

   it 'parses argument empty lists' do
      subject.parse('(null? ())').should == ['null?', []]
   end

   it 'parses a name' do
      subject.parse('foobar').should == 'foobar'
   end

   it 'parses a string literal' do
      subject.parse('"foobar"').should == '"foobar"'
   end

   it 'parses an integer literal' do
      subject.parse('1234567').should == '1234567'
   end

   it 'parses a float literal' do
      subject.parse('12.24').should == '12.24'
   end

   it 'parses a non-nested s-expr' do
      subject.parse('(+ 1 2 3)').should == ['+', '1', '2', '3']
   end

   it 'parses a non-nested s-expr' do
      subject.parse('(quux? 1 2 3 72 9 x)').should == ['quux?', '1', '2', '3', '72', '9', 'x']
   end

   it 'parses a less well-behaved non-nested s-expr' do
      subject.parse('( quux?   1 2 3  72 9 x   )').should == ['quux?', '1', '2', '3', '72', '9', 'x']
   end

   it 'parses a nested s-expr' do
      subject.parse('(+ 1 (- 100 32) 3)').should == ['+', '1', ['-', '100', '32'], '3']
   end

   it 'parses a nested s-expr' do
      subject.parse('(+ 1 (- 100 (car "foo" "bar")) 3)').should == ['+', '1', ['-', '100', ['car', '"foo"', '"bar"']], '3']
   end
  end

  describe '#eval' do
    it 'evaluates nil' do
      subject.hal_eval('nil', {}).should == nil
      subject.hal_eval(['quote', []], {}).should == []
    end

    it 'evaluates numbers' do
      subject.hal_eval('1234', {}).should == 1234
      subject.hal_eval('1234.34', {}).should == 1234.34
      subject.hal_eval('-0.3467', {}).should == -0.3467
    end

    it 'evaluates strings' do
      subject.hal_eval('"what the fuck"', {}).should == 'what the fuck'
    end

    it 'evaluates names' do
      subject.hal_eval('x', {'x' => 42}).should == 42
      subject.hal_eval('cons', {}).should be_an_instance_of(Proc)
      subject.hal_eval('car', {}).should be_an_instance_of(Proc)
      subject.hal_eval('cdr', {}).should be_an_instance_of(Proc)
    end

    it 'evaluates normal functions' do
      subject.hal_eval(['cons', '42', '51'], {}).should == [42, 51]
      subject.hal_eval(['car', ['quote', [42, 32]]], {}).should == 42
      subject.hal_eval(['cdr', ['quote', [42, 32]]], {}).should == [32]
    end

    it 'evaluates special forms' do
      subject.hal_eval(['quote', ['42', '35', '11']], {}). should == ['42', '35', '11']
    end
  end

  describe '#string?' do
    it 'returns true for string' do
      subject.string?('"to be or not to be"').should == true
      subject.string?('"234234234"').should == true
    end

    it 'returns false for non-strings' do
      subject.string?('(+ 1 2 3 4)').should == false
      subject.string?('234234234').should == false
      subject.string?('"234234"234"').should == false
    end
  end

  describe '#integer?' do
    it 'returns true for integers' do
      subject.integer?('1234').should == true
      subject.integer?('1234ewesfd').should == false
      subject.integer?('1234.23423').should == false
      subject.integer?('0.23423').should == false
    end
  end

  describe '#real?' do
    it 'returns true for reals' do
      subject.real?('1234').should == false
      subject.real?('1234ewesfd').should == false
      subject.real?('1234.23423').should == true
      subject.real?('-0.23423').should == true
    end
  end

  describe '#list?' do
    it 'returns false for atoms' do
      subject.list?(1234).should == false
      subject.list?('hello').should == false
    end

    it 'returns true for lists' do
      subject.list?([]).should == true
      subject.list?(['+', 1, 2, 3]).should == true
    end
  end

  describe '#atom?' do
    it 'returns true for atoms' do
      subject.atom?(1234).should == true
      subject.atom?('hello').should == true
    end

    it 'returns false for lists' do
      subject.atom?([]).should == false
      subject.atom?(['+', 1, 2, 3]).should == false
    end
  end
end
