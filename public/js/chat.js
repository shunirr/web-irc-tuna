var ws;
var channels = {};

function formatDate(unixtime) {
  var time = new Date();
  time.setTime(unixtime * 1000);
  var timeStr = $.format.date(time.toString(), "HH:mm");
  return timeStr;
}
function now() {
  var time = new Date();
  var timeStr = $.format.date(time.toString(), "HH:mm");
  return timeStr;
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
      channels[channel].append(
        $('<p>')
          .append($('<span>').attr({ class: 'time' }).text(formatDate(parseInt(data.time))))
          .append($('<span>').attr({ class: 'nick' }).text(data.from.id))
          .append($('<span>').attr({ class: 'body ' + data.mode }).text(data.body))
      );
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
function send() {
  var channel = $('#channels-tab li[class=active]').text();
  var body = $('input[name=body]');
  if (channel && body.val()) {
    ws.send( $.toJSON(['PRIVMSG', channel, body.val()]) );
  }
  channels[channel].append(
    $('<p>')
      .append($('<span>').attr({ class: 'time' }).text(now()))
      .append($('<span>').attr({ class: 'nick' }).text("ME"))
      .append($('<span>').attr({ class: 'body' }).text(body.val()))
  );
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
