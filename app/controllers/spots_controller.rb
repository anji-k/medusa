class SpotsController < ApplicationController
  respond_to :html, :xml, :json
  before_action :find_resource
  load_and_authorize_resource

  def edit
    respond_with @spot, layout: !request.xhr?
  end

  def update
    @spot.update_attributes(spot_params)
    respond_with @spot, location: attachment_file_path(@spot.attachment_file)
  end
  
  def property
    respond_with @spot, layout: !request.xhr?
  end
  
  def picture
    respond_with @spot, layout: !request.xhr?
  end

  private

  def spot_params
    params.require(:spot).permit(
      :name,
      :description,
      :spot_x,
      :spot_y,
      :target_uid,
      :radius_in_percent,
      :stroke_color,
      :stroke_width,
      :fill_color,
      :opacity,
      :with_cross,
      record_property_attributes: [
        :global_id,
        :user_id,
        :group_id,
        :owner_readable,
        :owner_writable,
        :group_readable,
        :group_writable,
        :guest_readable,
        :guest_writable
      ]
    )
  end

  def find_resource
    @spot = Spot.find(params[:id])
  end

end
