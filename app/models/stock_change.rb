class StockChange < ActiveRecord::Base
  belongs_to :delivery
  belongs_to :order
  belongs_to :stock_taking
  belongs_to :stock_article

  validates_presence_of :stock_article_id, :quantity
  validates_numericality_of :quantity
  validates :new_quantity_available,
    numericality: {only_integer: true},
    allow_nil: true,
    allow_blank: true

  # allow the input of new_quantity_available; calculate quantity accordingly
  before_validation :handle_new_quantity_available

  after_save :update_article_quantity
  after_destroy :update_article_quantity

  def old_quantity_available
    stock_article.quantity_available.to_i - quantity_was.to_i
  end
  
  def new_quantity_available=(new_quantity_available)
    quantity_will_change! # do not skip the save (and validation + callbacks)
    @new_quantity_available = new_quantity_available
  end

  def new_quantity_available
    return @new_quantity_available unless @new_quantity_available.nil?
    return nil if (quantity.nil? or marked_for_destruction?) # fresh records and records to be deleted
    old_quantity_available + quantity.to_i
  end

  protected

  def update_article_quantity
    stock_article.update_quantity!
  end
  
  def handle_new_quantity_available
    if @new_quantity_available.nil? or @new_quantity_available.to_s.empty?
      self.quantity = 0
      mark_for_destruction
      return true
    end
    
    @new_quantity_available = Integer(@new_quantity_available)
    self.quantity = @new_quantity_available - old_quantity_available
  rescue
    self.quantity = quantity_was
    errors.add :new_quantity_available, :not_an_integer
    return false # do not validate or save (when called by before_validate)
  end
end

