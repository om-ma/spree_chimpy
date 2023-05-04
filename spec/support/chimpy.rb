RSpec.configure do |config|

  config.before do
    SpreeChimpy.reset
  end
end