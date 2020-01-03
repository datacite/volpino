require "rails_helper"

describe "UsersController", type: :controller, vcr: true do
  subject { UsersController.new }

  it "get_meta" do
    response = subject.get_meta
    expect(response["created"].first).to eq("count"=>378891, "id"=>"2011", "title"=>"2011")
    expect(response["published"].first).to eq("count"=>57136, "id"=>"0001", "title"=>"0001")
    expect(response["resourceTypes"].first).to eq("count"=>6615110, "id"=>"dataset", "title"=>"Dataset")
  end

  it "get_meta with user_id" do
    user_id = "0000-0003-1419-2405"
    response = subject.get_meta(user_id: user_id)
    expect(response["created"].first).to eq("count"=>2, "id"=>"2012", "title"=>"2012")
    expect(response["published"].first).to eq("count"=>4, "id"=>"2012", "title"=>"2012")
    expect(response["resourceTypes"].first).to eq("count"=>116, "id"=>"text", "title"=>"Text")
  end
end
