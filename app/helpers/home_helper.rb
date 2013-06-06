module HomeHelper
  def short_date(date)
    date.strftime('%m/%d %a')
  end
end
