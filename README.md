# Introduce ActionCable

In this post, I only introduce main parts of ActionCable.

ActionCable is a new feature in Rails 5+. ActionCable brings WebSockets to your Rails application, allowing “for real-time features to be written in Ruby in the same style and form as the rest of your Rails application, while still being performant and scalable.” (ActionCable Overview) Of course Ruby can only be run on the server, so it also provides a JavaScript framework as part of the stack.

### 1. We must understand about "What's WebSocket ?"

Unlike HTTP requests, WebSockets are connections that are stateful. This means that the connection between a client and a server remains constant and connected. In this scenario. either party (the client or the server) has the ability to initiate a request or a message. The end result is direct interaction between browser and server.

### 2. What is ActionCable ?

Since the Rails controllers are purpose-built to handle HTTP requests, Rails has devised a different way to handle its integration of WebSockets. Rails 5 apps have a new directory in the app directory called channels. Channels acts as controllers for WebSocket requests by encapsulating the logic about particular works of unit, such as chat messages or notifications. The channels can be subscribed to client-side in order to transmit data from-and-to the channel or multiple channels.

Action Cable can be run on a stand-alone server, or we can configure it to run on its own processes within the main application server.

Action Cable uses the Rack socket hijacking API to take over control of connections from the application server. Action Cable then manages connections internally, in a multithreaded manner, layering as many channels as you care to define over that socket connection.

For every instance of your application that spins up, an instance of Action Cable is created, using Rack to open and maintain a persistent connection, and using a channel mounted on a sub-URI of your main application to stream from certain areas of your application and broadcast to other areas.

Action Cable offers server-side code to broadcast certain content (think new messages or notifications) over the channel, to a subscriber. The subscriber is instantiated on the client-side with a handy JavaScript function that uses jQuery to append new content to the DOM.

Action Cable uses Redis as a data store for transient data, syncing content across instances of your application.

Pub/Sub streams are powered by Redis’ Pub/Sub feature. This allows more than one Rails server to share state i.e. publishing to Redis will result in messages being delivered to all servers. Every stream uses a separate Redis channel, which is a good thing.

The unit of message distribution is a pub/sub stream, every message published is done via a stream broadcast in ActionCable.

#### a. Server Side

Rails 5 applications have a new directory called app/channels with:
- app/channels/application_channel/connection.rb
- app/channels/application_channel/channel.rb

`ApplicationCable::Connection` is used for general authorization. For example, we could use this module to query the database for a specific user that is making the connection and ensure that they are allowed to listen. For this project, we do not have any users and, thus, need no code here.

`ApplicationCable::Channel` is used much like `ApplicationController` in our normal stack. This class is the base of all other channels. Notice that all other channels in the project inherit from this class. You can use this class to perform shared logic that can be used between channels.



Create a new file inside that directory with the following code: 

`channels/notifications_channel.rb` 

```ruby
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from("notifications_#{current_user.id}_channel")
  end

  def unsubscribed
  end

  def send_message(data)
    conversation = Conversation.find_by(id: data['conversation_id'])
    if conversation && conversation.participates?(current_user)
      personal_message = current_user.personal_messages.build({body: data['message']})
      personal_message.conversation = conversation
      personal_message.save!
    end
  end
end
```

`subscribed` and `unsubscribed` are hooks that run when someone starts or stops listening to a socket.

The `stream_from` method is used to subscribe to a string that you define

`send_message` is the method we are calling from the client side. That method checks whether a conversation exists and a user has rights to access it. This is a very important step, because otherwise, anyone may write to any conversation. If it is true, just save the new message. Note that when you make any changes to the files inside the channels directory, you must reboot web server (even in development).

#### b. Broadcasting Changes

After the message is saved, it should be sent back to the participants of a conversation and be rendered on the page. One of the ways to achieve this is by using a callback and a background job:

`models/personal_message.rb` :

```ruby
# ...
after_create_commit do
  NotificationBroadcastJob.perform_later(self)
end
```

`after_create_commit` is called only after a record was saved and committed.

Here is the background job to broadcast a new message:

We have `jobs/notifications_broadcast_job.rb` :

```ruby
class NotificationBroadcastJob < ApplicationJob
    queue_as :default

    def perform(personal_message)
      message = render_message(personal_message)
      ActionCable.server.broadcast "notifications_#{personal_message.user.id}_channel",
                                   message: message,
                                   conversation_id: personal_message.conversation.id

      ActionCable.server.broadcast "notifications_#{personal_message.receiver.id}_channel",
                             notification: render_notification(personal_message),
                             message: message,
                             conversation_id: personal_message.conversation.id
    end

    private

    def render_notification(message)
      NotificationsController.render partial: 'notifications/notification', locals: {message: message}
    end

    def render_message(message)
      PersonalMessagesController.render partial: 'personal_messages/personal_message',
                                        locals: {personal_message: message}
    end
  end
```

`ActionCable.server.broadcast` sends data via a channel. Since, inside `notifications_channel.rb`, we said `stream_from("notifications_#{current_user.id}_channel")`, the same name will be used in the background job.

#### c. Client side:

We have `app/assets/javascripts/cable.js` :

```javascript

//= require action_cable
//= require_self
//= require_tree ./channels

(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();

}).call(this);
```

This will ready a consumer that'll connect against /cable on your server by default. The connection won't be established until you've also specified at least one subscription you're interested in having.


### 3. Usage :

First, must rails 5+. We need enable cable in `config/routes.rb`, adding this line: 

```ruby
mount ActionCable.server => '/cable'
```

- `layouts/application.html.erb` adding this line:

```
...
    <head>
        ...
        <%= action_cable_meta_tag %>
        ...
    </head>
...
```

- I develope with local, so `config/environments/development.rb` :

```ruby
config.action_cable.url = "ws://localhost:3000/cable"
```

- Then, we create channel, broadcast job, ...









