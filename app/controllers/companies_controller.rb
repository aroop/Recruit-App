class CompaniesController < ApplicationController
  
  before_filter :load_company, :only => [ :show, :edit, :update, :destroy ]
  
  def new
    @company = current_account.companies.new
    @company.build_address
  end
  
  def edit
    
  end
  
  def create
    @company = current_account.companies.new(params[:company])

    respond_to do |format|
      if @company.save
        flash[:notice] = 'Company was successfully created.'
        format.html { redirect_to(@company) }
        format.xml  { render :xml => @company, :status => :created, :location => @company }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end    
  end
  
  def index
    @companies = current_account.companies.paginate(:page => params[:page])
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @companies }
    end
  end
  
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @company }
    end    
  end
  
  def update
    respond_to do |format|
      if @company.update_attributes(params[:company])
        flash[:notice] = 'Company was successfully updated.'
        format.html { redirect_to(@company) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @company.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @company.destroy

    respond_to do |format|
      format.html { redirect_to(movies_url) }
      format.xml  { head :ok }
    end
  end  
  
  protected
  
  def load_company
    @company = current_account.companies.find(params[:id])
  end
  
end