module ApplicationHelper
  include Pagy::Frontend
  ALERT_TYPES = {
    success: 'alert-success',
    error: 'alert-danger',
    alert: 'alert-warning',
    notice: 'alert-info'
  }.freeze

  def bootstrap_class_for(flash_type)
    ALERT_TYPES[flash_type.to_sym] || flash_type.to_s
  end

  def page_title
    title = ""
    title += "#{@page_title} - " if @page_title.present?
    title += "IPFS DHT Explorer"
  end
end
