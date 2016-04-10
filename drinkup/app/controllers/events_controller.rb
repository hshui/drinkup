class EventsController < ApplicationController

  before_action :redirect_if_not_logged_in
  before_action :correct_user, only: [:edit, :update, :destroy]
  before_action :set_cache_headers
  
  def test
  end
  
  def index
    # Right now we are just returning all events to test display event data on the index page
    # We will be removing this, once we are able to use jQuery to populate event data to display.
    # @events = Event.all
    # @events_attending = current_user.attendees.attending.select("event_id").map(&:event_id)
  end

  def getEvents
    @lat_lng = cookies[:lat_lng].split("|")

    @events = Event.within(5, :origin => [@lat_lng[0], @lat_lng[1]]).where('end_time > ?', Time.now)
    @events_attending = current_user.attendees.attending.pluck(:event_id)

    @events.each do |event|
      event.count = event.attendees.attending.count
    end

    respond_to do |format|
      format.html {redirect_to "index"}
      format.json {render :json => {:events => @events.as_json(:methods => [:count]), :events_attending => @events_attending }}
    end
  end

  def getTopConversations
    event = Event.find(params[:id])
    top_conversations = event.getTopConversations

    respond_to do |format|
      format.html {redirect_to "index"}
      format.json {render :json => {:top_conversations => top_conversations}}
    end
  end

  def show
    @event = Event.find(params[:id])
    #if event does not have a chat create one
    #used to subscribe to specific chat
    if !Chat.exists?(:event_id => params[:id])
      @chat = @event.create_chat(params[:chat])
    else
      @chat = Chat.find_by(event_id: @event.id)
    end

    @creator_status = current_user.attendees.creator_of_event(@event).pluck(:is_creator)
    @messages = @chat.messages
    @message = Message.new

    if @creator_status.blank?
      @creator_status = false
    end
  end

  def new
  	@event = Event.new
  end

  def create
  	@event = Event.new(event_params)
 
  	if @event.save
      @event.attendees.create(:user => current_user, :is_attending => true, :is_creator => true)
      #http://stackoverflow.com/questions/3839779/rails-create-on-has-one-association
  		redirect_to @event
  	else
  		render 'new'
  	end
  end

  def update
   @event = Event.find(params[:id])
 
   if @event.update(event_params)
    redirect_to @event
   else
    render 'edit'
   end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def delete
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    attendees_for_event = Attendee.where(:event_id => @event.id)
    
    attendees_for_event.each do |attendee|
      attendee.destroy
    end

    redirect_to events_path
  end

  def join
    @event = Event.find(params[:id])

    attendee = current_user.attendees.where(:event_id => @event.id).first
    drinkupAttendeeLimit = 8

    if (@event.attendees.attending.count <= drinkupAttendeeLimit)
      if attendee.blank?
        @event.attendees.create(:user => current_user, :is_attending => true)
      else
        attendee.update_attributes(:is_attending => true)
      end
    else 
      flash[:danger] = "You cannot join a drinkup that's already full."
    end

    redirect_to @event
  end

  def unjoin
    @event = Event.find(params[:id])

    attendee = current_user.attendees.attending_event(@event).first

    if attendee.update_attributes(:is_attending => false)
      redirect_to @event
    else
      render('index')
    end
  end

  private
  def event_params
    params.require(:event).permit(:name, :lat, :lng, :start_time, :end_time, :gender, :place_id, :place_name, :place_address)
  end

  # Confirms the correct user.
  def correct_user
    @event = Event.find(params[:id])
    if current_user.attendees.creator_of_event(@event).blank?
      flash[:danger] = "You can't edit someone else's event."
      redirect_to @event
    end
  end

end
