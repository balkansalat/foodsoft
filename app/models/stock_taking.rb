class StockTaking < ActiveRecord::Base
  has_many :stock_changes, :dependent => :destroy
  has_many :stock_articles, :through => :stock_changes

  validates_presence_of :date
  validate :stock_articles_must_be_unique

  accepts_nested_attributes_for :stock_changes
  
  def new_stock_changes=(stock_change_attributes)
    for attributes in stock_change_attributes
      # Allow for zero stock_changes. This is a confirmation of the current stock quantity.
      # Note that this version only supports the input via new_quantity_available
      stock_changes.build(attributes) unless (attributes[:new_quantity_available].nil? or attributes[:new_quantity_available].empty?)
    end
  end
  
  # preprocess the data passed to stock_changes_attributes=
  # (see your gem lib/active_record/nested_attributes.rb)
  original_assignment = instance_method('stock_changes_attributes=')
  define_method('stock_changes_attributes=') do |stock_changes_attributes|
    raise ArgumentError unless stock_changes_attributes.is_a?(Hash)
    
    # if id of a deleted StockChange is given: create a new StockChange instead
    stock_changes_attributes.each_value do |stock_change_attr|
      if stock_change_attr['id'].present?
        stock_change_attr.delete(:id) unless StockChange.exists?(id: stock_change_attr['id'])
      end
    end
    
    # TODO: if a _new_ StockChange shall be created for a StockArticle which is
    # already referenced by another StockChange of this StockTaking: overwrite
    
    # pass modified arguments to original function
    original_assignment.bind(self).(stock_changes_attributes)
  end
  
  # add StockChanges for missing StockArticles
  def include_all_stock_articles
    StockArticle.undeleted.each do |a|
      unless stock_articles.include? a
        stock_changes.build(:stock_article => a, :quantity => nil)
      end
    end
  end
  
  protected
  
  def stock_articles_must_be_unique
    unless stock_changes.reject{|sc| sc.marked_for_destruction?}.map {|sc| sc.stock_article.id}.uniq!.nil?
      errors.add(:base, I18n.t('model.stock_taking.each_stock_article_must_be_unique'))
    end
  end
end

