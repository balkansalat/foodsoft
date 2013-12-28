class StockTakingsController < ApplicationController
  inherit_resources

  def index
    @stock_takings = StockTaking.order('date DESC').page(params[:page]).per(@per_page)
  end

  def new
    @stock_taking = StockTaking.new
    @stock_taking.date = Date.today #TODO: move to model/database
    @stock_taking.include_all_stock_articles
  end

  def create
    @stock_taking = StockTaking.new(params[:stock_taking])
    
    if @stock_taking.save
      flash[:notice] = I18n.t('stock_takings.create.notice')
      redirect_to @stock_taking
    else
      render :action => "new"
    end
  end

  def edit
    @stock_taking = StockTaking.find(params[:id])
    @stock_taking.include_all_stock_articles
  end

  def update
    @stock_taking = StockTaking.find(params[:id])

    if @stock_taking.update_attributes(params[:stock_taking])
      flash[:notice] = I18n.t('stock_takings.update.notice')
      redirect_to @stock_taking
    else
      render :action => "edit"
    end
  end
  
  def form_on_stock_article_create # See publish/subscribe design pattern in /doc.
    stock_article = StockArticle.find(params[:id])
    @stock_change = stock_article.stock_changes.new(:quantity => nil)
    
    render :layout => false
  end

  def form_on_stock_article_update # See publish/subscribe design pattern in /doc.
    @stock_article = StockArticle.find(params[:id])
    
    render :layout => false
  end
end
