require "rails_helper"

describe "UsersController", type: :controller, vcr: true do
  subject { UsersController.new }

  it "get_meta" do
    response = subject.get_meta
    expect(response["created"].first).to eq("count"=>29, "id"=>"2011", "title"=>"2011")
    expect(response["resourceTypes"].first).to eq("count"=>323850, "id"=>"text", "title"=>"Text")
  end

  it "get_meta with user_id" do
    user_id = "0000-0003-1419-2405"
    response = subject.get_meta(user_id: user_id)
    expect(response["created"].first).to eq("count"=>2, "id"=>"2018", "title"=>"2018")
    expect(response["resourceTypes"].first).to eq("count"=>27, "id"=>"text", "title"=>"Text")
  end
end