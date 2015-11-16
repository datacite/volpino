module Dateable
  extend ActiveSupport::Concern

  included do
    def get_date_parts(iso8601_time)
      return { "date_parts" => [[]] } if iso8601_time.nil?

      year = iso8601_time[0..3].to_i
      month = iso8601_time[5..6].to_i
      day = iso8601_time[8..9].to_i
      { 'date-parts' => [[year, month, day].reject { |part| part == 0 }] }
    end

    def get_year_month(iso8601_time)
      return [nil, nil] if iso8601_time.nil?

      year = iso8601_time[0..3].to_i
      month = iso8601_time[5..6].to_i

      [year, month]
    end

    def get_date_parts_from_parts(year, month = nil, day = nil)
      { 'date-parts' => [[year.to_i, month.to_i, day.to_i].reject { |part| part == 0 }] }
    end
    
    def get_iso8601_from_time(time)
      return nil if time.blank?

      Time.zone.parse(time.to_s).utc.iso8601
    end

    def get_iso8601_from_epoch(epoch)
      return nil if epoch.blank?

      # handle milliseconds
      epoch = epoch.to_i
      epoch = epoch / 1000 if epoch > 9999999999
      Time.at(epoch).utc.iso8601
    end
  end
end
