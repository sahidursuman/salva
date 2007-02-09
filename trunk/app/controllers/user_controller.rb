require 'auth_user'
class UserController < ApplicationController
  helper :user
  include AuthUser
  # To require logins, use:
  #
  #   before_filter :login_required                            
  #   restrict all actions
  #   before_filter :login_required, :only => [:edit, :update] 
  #   only restrict these actions
  # 
  #   To skip this in a subclassed controller:
  #
  #   skip_before_filter :login_required
  skip_before_filter :login_required
  skip_before_filter :rbac_required
  #filter_parameter_logging :passwd

  public
  def index
    login
  end
  
  def login
    return true unless request.post?
    if auth?(params[:user][:login],params[:user][:passwd])
      session[:user] = User.find(:first, :conditions => ['login = ?', params[:user][:login]]).id
      flash[:notice] = "Bienvenido (a), ha iniciado una sesión en el SALVA!"
      redirect_back_or_default :controller => 'navigator'
    else
      flash[:notice] = "El login o el password es incorrecto!"
    end
  end
  
  def login_by_token
    if auth_user_by_id_and_token?(params[:id], params[:token])
      session[:user] = params[:id]
      flash[:notice] = "Bienvenido (a), ha iniciado una sesión en el SALVA!"
      redirect_back_or_default :controller => 'navigator'
    else
      flash[:notice] = "El pase proporcionado es inválido!"
      render :action => 'login'
    end
  end
  
  def new
    @user = User.new
  end
  
  def create
    return unless request.post?
    @user = User.new(@params[:user])
    if @user.save
      url = url_for(:controller => 'user', :action => 'activate', :id => @user.id, :token => @user.token)
      UserNotifier.deliver_new_notification(@user, url) 
      render :action => 'create'
    else
      render :action => 'new'
    end
  end

  # Method for activating the current user
  def activate
    @user = User.find(:first, :conditions => [ 'id = ? AND token = ? AND token_expiry >= ?',
                        params[:id], params[:token], 0.minutes.from_now ])
    if @user
      reset_session # Reset old sessions if exists
      @user.update_attributes({ :userstatus_id => 2,
                                :token => nil, :token_expiry => nil })
      url = url_for(:controller => 'user', :action => 'login')
      UserNotifier.deliver_activation(@user, url) 
      render :action => 'activated'
    else
      render :action => 'invalid'
    end
  end

  # Send out a forgot-password email.
  def forgot_password
    return unless request.post?
    @user = User.find_first(['email = ?', params[:user]['email']])
    if @user
      @user.update_attributes({ :token => token_string(10),
                                :token_expiry => 7.days.from_now })
      url = url_for(:controller => 'user', :action => 'login_by_token', 
                    :id => @user.id, :token => @user.token)
      UserNotifier.deliver_forgot_password(@user, url) 
      render :action => 'forgot_password_done'
    else
      flash[:notice] = "El correo #{params[:user]['email']} NO existe en el salva!"
    end
  end
  
  def logout
    reset_session
  end
end
