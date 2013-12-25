require 'pp'

class Hal
  attr_accessor :globals

  def initialize
    @globals = {
      'cons' => lambda {|a, b| [a, b]},
      'car' => lambda {|l| l[0]},
      'cdr' => lambda {|l| l[1..-1]},
      'quote' => lambda {|locals, l| l},
      '#t' => true,
      '#f' => false,
      'null?' => lambda {|x| null?(x)},
      'boolean?' => lambda {|x| boolean?(x)},
      'if' => lambda {|locals, condition, then_exp, else_exp| hal_eval(condition, locals) ? hal_eval(then_exp, locals) : hal_eval(else_exp, locals)},
      '+' => lambda {|*args| args.inject{|sum, x| sum + x }},
      '-' => lambda do |*args| 
        args[1..-1].inject(args[0]){|sum, x| sum - x }
      end,
      '*' => lambda {|*args| args.inject(1){|sum, x| sum * x }},
      '/' => lambda {|*args| args[1..-1].inject(args[0]){|sum, x| sum / x }},
      'zero?' => lambda {|x| x == 0},
      'positive?' => lambda {|x| x > 0},
      'negative?' => lambda {|x| x < 0},
      'odd?' => lambda {|x| x % 2 != 0},
      'even?' => lambda {|x| x % 2 != 0},
      'max' => lambda {|*args| args.max},
      'min' => lambda {|*args| args.min},
      'abs' => lambda {|x| x.abs},
      'not' => lambda {|b| not b},
      'list' => lambda {|*args| args},
      'and' => lambda do |locals, *args| 
        result = true
        args.each do |arg|
          result = hal_eval(arg, locals)
          if not result
            return result
          end
        end
        result
      end,
      'or' => lambda do |locals, *args| 
        result = false
        args.each do |arg|
          result = hal_eval(arg, locals)
          if result
            return result
          end
        end
        result
      end,
      'lambda' => lambda do |locals, params, body|
        lambda do |*args|
          params.each_with_index { |elem, i| locals[elem] = args[i] }
          hal_eval(body, locals)
        end
      end,
      'define' => lambda do |locals, key, value|
        @globals[key] = hal_eval(value, locals)
      end,
      'let' => lambda do |locals, bindings, body|
        new_locals = {}
        bindings.each { |key, value| new_locals[key] = hal_eval(value, locals)}
        locals = locals.merge(new_locals)
        hal_eval(body, locals)
      end,
      'let*' => lambda do |locals, bindings, body|
        bindings.each { |key, value| locals[key] = hal_eval(value, locals)}
        hal_eval(body, locals)
      end,
      'cond' => lambda do |locals, *args|
         args.each do |condition, result|
           return hal_eval(resul, locals) if hal_eval(condition, locals)
         end
         if args.length > 0 && args[-1][0] == 'else'
           args[-1][1]
         end
      end

      # (cond ((> 3 2) 'greater)
      #       ((< 3 2) 'less)) 

      # cond
      # letrec
    }
    @special_forms = [
      'quote',
      'if',
      'define',
      'lambda',
      'and',
      'or',
      'let',
      'let*'
    ]
  end

  def special? blub
    @special_forms.include?(blub[0])
  end

  def eval_special blub, locals
    @globals[blub[0]].call(locals, *blub[1..-1])
  end

  def apply blub
    blub[0].call(*blub[1..-1])
  end

  def null? blub
    blub == []
  end

  def hal_eval blub, locals
    if list? blub
      if null? blub
        blub
      elsif special? blub
        eval_special blub, locals
      else
        apply blub.map {|x| hal_eval(x, locals)}
      end
    else
      if integer?(blub)
        blub.to_i
      elsif real?(blub)
        blub.to_f
      elsif string?(blub)
        blub[1..-2]
      else
        if locals[blub]
          locals[blub]
        else
          @globals[blub]
        end
      end
    end
  end

  def prompt
    print '> '
    $stdout.flush
  end

  def repr(blub)
    if list?(blub)
      '(' + blub.join(' ') + ')'
    elsif boolean?(blub)
      if blub
        '#t'
      else
        '#f'
      end
    elsif string?(blub)
      '"' + blub + '"'
    else
      blub
    end
  end

  def repl
    while true
      prompt
      puts repr(hal_eval(parse(gets.chomp), {}))
    end
  end

  def integer?(s)
    !!(s =~ /\A(-)?[0-9]+\z/)
  end
  
  def real?(s)
    !!(s =~ /\A(-)?[0-9]+\.[0-9]+\z/)
  end

  def string?(s)
    !!(s =~ /\A"[^"]*"\z/)
  end

  def list?(o)
    o.instance_of?(Array)
  end
  
  def atom?(o)
    not list?(o)
  end

  def boolean?(s)
    s.instance_of?(TrueClass) or s.instance_of?(FalseClass)
  end

  def parse_s(s)
    pp s
    if s[0] == '('
      len = s.length
      i = 0
      subexpr = s[i]
      opened = 1
      i += 1
      while i < len and opened != 0
        if s[i] == '('
          opened += 1
        end
        if s[i] == ')'
          opened -= 1
        end
        subexpr += s[i]
        i += 1
      end
      subexpr
    else
      s
    end
  end

  def parse(s)
    len = s.length
    if s[0] == '(' and s[len - 1] == ')'
      result = []
      s = s[1...len-1]
      len = s.length
      i = 0
      while i < len
        if s[i] == '('
          subexpr = s[i]
          opened = 1
          i += 1
          while i < len and opened != 0
            if s[i] == '('
              opened += 1
            end
            if s[i] == ')'
              opened -= 1
            end
            subexpr += s[i]
            i += 1
          end
          item = parse(subexpr)
        elsif s[i] == "'"
          quoted = parse_s(s[(i+1)..-1])
          item = parse "(quote #{quoted})"
          i += quoted.length
        else
          item = ''
          while s[i] != ' ' and i < len
            item += s[i]
            i += 1
          end
        end
        result << item unless item == ''
        i += 1
      end
      result
    else
      if s[0] == "'"
        parse "(quote #{parse_s(s[1..-1])})"
      else
        s
      end
    end
  end
end
