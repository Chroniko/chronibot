require "icalendar"
require "httparty"

class Spoilers
  ICAL_URL = "https://rushsync.com/rushsync.ics?key=01415bec62de413baf013ab7bb55bdc8&sub=462e615680174bb6b995983f4868d8d6"

  attr_reader :week_offset

  def initialize(week_offset: 0)
    @week_offset = week_offset
  end

  def title
    if week_offset.zero?
      "This week"
    else
      "Coming up in #{week_offset} week#{ "s" if week_offset > 1}"
    end
  end

  def current_events
    calendar.events
      .select { |event| event.dtstart.cweek == target_week }
      .map { |event| parse_event(event) }
      .sort_by(&:category)
  end

  def target_week
    current_week + week_offset
  end

  def current_week
    Date.today.cweek
  end

  def parse_event(event)
    Event.new(event.summary)
  end

  def calendar
    @calendar ||= Icalendar::Calendar.parse(ical_body).first
  end

  def ical_body
    HTTParty.get(ICAL_URL)
  end

  class Event
    def initialize(summary)
      @attrs = /\[(?<category>[^\]]+)\] (?<name>.+)/.match(summary).named_captures
    end

    def category
      @attrs.fetch("category")
    end

    def name
      @attrs.fetch("name")
    end
  end
end
