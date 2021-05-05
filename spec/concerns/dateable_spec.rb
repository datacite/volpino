require "rails_helper"

describe Claim do
  describe "get_iso8601_from_epoch" do
    it "should handle seconds" do
      result = subject.get_iso8601_from_epoch(1350426975)
      expect(result).to eq("2012-10-16T22:36:15Z")
    end

    it "should handle milliseconds" do
      result = subject.get_iso8601_from_epoch(1350426975660)
      expect(result).to eq("2012-10-16T22:36:15Z")
    end

    it "should handle strings" do
      result = subject.get_iso8601_from_epoch("1350426975")
      expect(result).to eq("2012-10-16T22:36:15Z")
    end

    it "should handle nil" do
      result = subject.get_iso8601_from_epoch(nil)
      expect(result).to be_nil
    end
  end

  describe "get_parts_from_date_parts" do
    it "should handle full date" do
      date_parts = { "date-parts" => [[2015, 10, 26]] }
      result = subject.get_parts_from_date_parts(date_parts)
      expect(result).to eq("year" => 2015, "month" => 10, "day" => 26)
    end

    it "should handle year-month only" do
      date_parts = { "date-parts" => [[2015, 10]] }
      result = subject.get_parts_from_date_parts(date_parts)
      expect(result).to eq("year" => 2015, "month" => 10)
    end

    it "should handle year only" do
      date_parts = { "date-parts" => [[2015]] }
      result = subject.get_parts_from_date_parts(date_parts)
      expect(result).to eq("year" => 2015)
    end
  end
end
