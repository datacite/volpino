require "rails_helper"

describe "UsersController", type: :controller, vcr: true do
  subject { UsersController.new }

  it "get_meta" do
    response = subject.get_meta
    expect(response["created"].first).to eq("count"=>115703, "id"=>"2020", "title"=>"2020")
    expect(response["published"].first).to eq("count"=>87276, "id"=>"2020", "title"=>"2020")
    expect(response["resourceTypes"].first).to eq("count"=>87106, "id"=>"dataset", "title"=>"Dataset")
  end

  it "get_meta with user_id" do
    user_id = "0000-0003-1419-2405"
    response = subject.get_meta(user_id: user_id)
    expect(response["created"].first).to eq("count"=>22, "id"=>"2020", "title"=>"2020")
    expect(response["published"].first).to eq("count"=>6, "id"=>"2020", "title"=>"2020")
    expect(response["resourceTypes"].first).to eq("count"=>12, "id"=>"dataset", "title"=>"Dataset")
  end
end
