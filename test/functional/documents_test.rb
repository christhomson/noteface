require File.expand_path '../../test_helper.rb', __FILE__

class DocumentsTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Noteface
  end

  def test_documents_should_load
    get '/documents.json'
    assert last_response.ok?
  end

  def test_documents_should_set_cors_header
    get '/documents.json'
    assert_equal '*', last_response.headers['Access-Control-Allow-Origin']
  end
end
