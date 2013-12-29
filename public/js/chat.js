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
function connect(url) {
  ws = new WebSocket(url);
  ws.onmessage = function(evt) {
    var data = JSON.parse(evt.data);
    if (data.from.type == 'channel') {
      var channel = data.from.channel;
      if (!hasChannel(channel)) {
        addChannel(channel);
      }
      addLog(channel, formatDate(parseInt(data.time)), data.from.id, data.mode, data.body);
      if (data.images && data.images.length > 0) {
        addImages(channel, formatDate(parseInt(data.time)), data.from.id, data.images);
      }
    }
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
  var body_class = 'body';
  if (mode) {
    body_class += ' ' + mode;
  }
  channels[channel].prepend(
    $('<p>')
      .append($('<span>').attr({ class: 'time' }).text(time))
      .append($('<span>').attr({ class: 'nick' }).text(nick))
      .append($('<span>').attr({ class: body_class }).html(body))
  );
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
  return channels[channel];
}
function addChannel(channel) {
  var hash = CybozuLabs.MD5.calc(channel);
  var anchor = $('<a>')
    .text(channel)
    .attr({ 
      href: '#' + hash,
    })
  .click(function (e) {
    e.preventDefault();
    $(this).tab('show');
  });

  $('#channels-tab').append( $('<li>').append(anchor) );
  channels[channel] = $('<div>').attr({ 'class' : 'tab-pane', 'id' : hash });
  $('#channels').append(channels[channel]);

  if ($('#channels-tab').children().size() == 1) {
    $('#channels-tab li:first').addClass('active');
    $('#channels div:first').addClass('active');
  }
}
