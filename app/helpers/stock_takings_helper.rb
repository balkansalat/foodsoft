module StockTakingsHelper
  
  def stock_change_status(stock_change)
    label_class = ' label-success'
    label_content = '1'
    if stock_change.new_quantity_available.nil?
      label_class = ''
      label_content = '0'
    end
    "<span class='stock_change_status label#{label_class}'>#{label_content}</span>".html_safe
  end
  
end
