module ApplicationHelper
  def to_fbdate(date, now = nil)
    return "" if date.nil?
    if now == nil then
      now = Time.now
    end
    diff =  now.to_i - date.to_i
    if diff < 0
      t(:furture) % diff
    elsif diff < 60
      t(:just_now)
    elsif diff < 3600
      t(:mintue_ago) % (diff/60)
    elsif diff < 86400
      t(:hour_ago)  % (diff/3600)
    elsif diff < (15*86400)
      t(:day_ago ) % (diff/86400)
    else
      date.strftime((date.year == now.year ? "":"%Y-")  + "%m-%d")
    end
  end
end
