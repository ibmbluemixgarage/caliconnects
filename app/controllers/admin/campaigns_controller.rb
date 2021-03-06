class Admin::CampaignsController < ApplicationController
  before_action :verify_is_admin

  def index
    @campaigns = Campaign.where(archived: false).order(updated_at: :desc).limit(20)
  end

  def archived
    @campaigns = Campaign.where(archived: true).order(updated_at: :desc).limit(20)
  end

  def new
    @campaign = Campaign.new
    @campaign.alerts.build
  end

  def create
    campaign = Campaign.new(
      campaign_params.merge(date: Time.now.to_i)
    )

    if campaign.save
      alert = Alert.new(alert_params.merge({ campaign_id: campaign.id }))

      redirect_to admin_campaigns_path, notice: "Campaign Created"

      if alert.save
        alert.send_notifications(params, preparedness_url)
      end
    end
  end

  def show
    @campaign = Campaign.find_by(id: params[:id])

    redirect_to admin_campaigns_path, alert: "Campaign Not Found" unless @campaign
  end

  def destroy
    @campaign = Campaign.find(params[:id]).update(archived: true)

    redirect_to admin_campaigns_path, notice: "Campaign Archived"
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name)
  end

  def alert_params
    alert_params = params.dig(:campaign, :alerts)

    if alert_params
      alert_params.permit(:severity, :description)
    else
      {}
    end
  end
end
