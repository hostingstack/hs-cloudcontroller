class PeriodicTask < Task
  def to_xml(opts = {})
    opts[:methods] = [opts[:methods]].flatten.compact + [:last_run, :start_hour, :interval]
    super(opts)
  end

  def last_run
    config[:last_run] ||= Time.at(0)
  end
  def last_run=(value)
    config[:last_run] = value
  end

  def start_hour
    config[:start_hour] ||= 0
  end

  def start_hour=(value)
    config[:start_hour] = value
  end

  def interval
    config[:interval] ||= :daily
  end

  def interval=(value)
    config[:interval] = value
  end

  def self.supported_intervals
    return [:daily, :hourly]
  end

  def next_run
    if interval == :daily
      offset_days = 0
      if now.hour > start_hour
        offset_days += 1
      end
      return Time.local(now.year, now.month, now.day, 0) + (offset_days * 86400) + (start_hour * 3600)
    elsif interval == :hourly
      hours = 0
      if last_run == Time.at(0)
        hours = start_hour
      elsif (now-last_run) >= 3600
        hours = now.hour
      else
        hours = now.hour + 1
      end
      return Time.local(now.year, now.month, now.day, hours)
    else
      raise "unknown interval"
    end
  end

  def should_run_now
    enabled and (next_run <= now)
  end

  def ran!
    config[:last_run] = now
    save!
  end

  protected
  def now
    Time.now
  end
end
