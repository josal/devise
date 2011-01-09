class Device::SessionsController < ApplicationController
  prepend_before_filter :require_no_authentication, :only => [ :new, :create ]
  include Devise::Controllers::InternalHelpers
  
    
  
  # WITH JSON RESPONSE       
  def sign_in_and_redirect(resource_or_scope, resource=nil, skip=false)
    scope      = Devise::Mapping.find_scope!(resource_or_scope)
    resource ||= resource_or_scope
    sign_in(scope, resource) unless skip
    respond_to do |format|
      format.html {redirect_to stored_location_for(scope) || after_sign_in_path_for(resource) }
      format.json { render :json => { :success => true, :session_id => request.session_options[:id], :resource => resource } }
    end
  end
  

  # GET /resource/sign_in
  def new
    unless flash[:notice].present?
      Devise::FLASH_MESSAGES.each do |message|
        set_now_flash_message :alert, message if params.try(:[], message) == "true"
      end
    end

    build_resource
    render_with_scope :new
  end

  # WITH JSON RESPONSE
  def create
    build_resource
    
    puts "LEGOOOOOOOOOOOOOOOOOO"
        
    if resource = authenticate(resource_name)
      set_flash_message :notice, :signed_in
      sign_in_and_redirect(resource_name, resource, true)
    elsif [:custom, :redirect].include?(warden.result)
      throw :warden, :scope => resource_name
    else
      set_now_flash_message :alert, (warden.message || :invalid)
      clean_up_passwords(build_resource)
      respond_to do |format|
        format.html { render_with_scope :new }
        format.json { render :json => {:success => false, :status => warden.message}}
      end
    end
  end  

  # GET /resource/sign_out
  def destroy
    set_flash_message :notice, :signed_out if signed_in?(resource_name)
    sign_out_and_redirect(resource_name)
  end

  protected

    def clean_up_passwords(object)
      object.clean_up_passwords if object.respond_to?(:clean_up_passwords)
    end
end