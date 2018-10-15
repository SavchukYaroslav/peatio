class Kek
  def initialize(kek=nil)
    instance_variable_set('@hello', kek)
  end
  
  def hello(hel)
    @hello || instance_variable_set('@hello', hel)
  end

end

puts Kek.new().hello('jk')

res = [1,3,5].each_with_object([]) do |n,a|
  a += Array(n)
end

puts res


