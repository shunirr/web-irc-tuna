var ws;
var channels = {};

function formatTime(dateStr) {
  var timeStr = $.format.date(dateStr, "HH:mm");
  return timeStr;
}

function formatDate(unixtime) {
  var time = new Date();
  time.setTime(unixtime * 1000);
  return formatTime(time.toString());
}

function loadChannels() {
  $.getJSON("/api/v1/networks/1/channels", function(data) {
    data.forEach(function(d) {
      if (!hasChannel(d)) {
        addChannel(d);
        loadRecentLogs(d);
      }
    });
  });
}

function loadRecentLogs(channel) {
  $.getJSON("/api/v1/channels/" + channel.id + "/logs", function(data) {
    data.forEach(function(d) {
      addLog(channel, formatDate(parseInt(d.created_at)), d.from, d.command, d.message);
    });
  });
}

function connect() {
  loadChannels();
  ws = new WebSocket(ws_url);

  ws.onmessage = function(evt) {
    var data = JSON.parse(JSON.parse(evt.data));
    var channel = data.channel;
    if (!hasChannel(channel)) {
      addChannel(channel);
    }
    addLog(channel, formatDate(parseInt(data.created_at)), data.from, data.command, data.message);
  };

  ws.onopen = function(handshake) {
    var password = $('input[name=pass]');
    ws.send(password.val());
    password.val('');
    $('#auth').hide();
    $('#send').show();
  };
}

function addImages(channel, time, nick, images) {
  var p = $('<p>')
      .append($('<span>').attr({ class: 'time' }).text(time))
      .append($('<span>').attr({ class: 'nick' }).text(nick));
  images.forEach(function(image) {
    p.append($('<img>').attr({ src: image }));
  });
  channels[channel].prepend(p);
}

function addLog(channel, time, nick, mode, body) {
  if (body) {
    var body_class = 'body';
    if (mode) {
      body_class += ' ' + mode;
    }
    channels[channel.id].prepend(
      $('<p>')
        .append($('<span>').attr({ class: 'time' }).text(time))
        .append($('<span>').attr({ class: 'nick' }).text(nick))
        .append($('<span>').attr({ class: body_class }).html(body))
    );
  }
}

function send() {
  var channel = $('#channels-tab li[class=active]').text();
  var body = $('input[name=body]');
  if (channel && body.val()) {
    ws.send( $.toJSON(['PRIVMSG', channel, body.val()]) );
  }
  body.val('');
}

function hasChannel(channel) {
  return channels[channel.id];
}

function addChannel(channel) {
  var anchor = $('<a>')
    .text(channel.name)
    .attr({ 
      href: '#' + channel.id,
    })
  .click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });

  $('#channels-tab').append( $('<li>').append(anchor) );
  channels[channel.id] = $('<div>').attr({ 'class' : 'tab-pane', 'id' : channel.id });
  $('#channels').append(channels[channel.id]);

  if ($('#channels-tab').children().size() == 1) {
    $('#channels-tab li:first').addClass('active');
    $('#channels div:first').addClass('active');
  }
}
