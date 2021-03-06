# Code originally created by the awesome members of Ubersicht community.
# I stole from so many I can't remember who you are, thank you so much everyone!
# Haphazardly adjusted and mangled by Pe8er (https://github.com/Pe8er)

command: "osascript 'Sidebar.widget/Playbox.widget/as/Get Current Track.applescript'"

refreshFrequency: '1s'

style: """

  white1 = rgba(white,1)
  white05 = rgba(white,0.5)
  white02 = rgba(white,0.2)
  black02 = rgba(black,0.2)

  width 176px
  overflow hidden
  white-space nowrap
  opacity 0

  .wrapper
    font-size 8pt
    line-height 11pt
    color white
    padding 8px

  .art
    width 44px
    height @width
    background-image url(Sidebar.widget/Playbox.widget/as/default.png)
    -webkit-transition background-image 0.5s ease-in-out
    background-size cover
    float left
    margin 0 8px 0 0
    position relative

    &__item
      position: absolute
      width: 100%
      height: 100%
      top: 0
      left: 0
      border-radius 50%

      &.bottom
        display none

  .text
    foat left

  .progress
    width: @width
    height: 2px
    background: white1
    position: absolute
    bottom: 0
    left: 0

  .wrapper, .album, .artist, .song
    overflow: hidden
    text-overflow: ellipsis

  .song
    font-weight: 700

  .album
    color white05

"""

render: (output) ->

  # Get our pieces.
  values = output.split(" ~ ")

  # Initialize our HTML.
  medianowHTML = ''

  # Progress bar things.
  tDuration = values[4]
  tPosition = values[5]
  tArtwork = values[6]

  # Create the DIVs for each piece of data.
  medianowHTML = "
    <div class='wrapper'>
      <div class='art'>
        <image class='art__item top' src='' />
        <image class='art__item bottom' src='' />
      </div>
      <div class='text'>
        <div class='song'>" + values[1] + "</div>
        <div class='artist'>" + values[0] + "</div>
        <div class='album'>" + values[2]+ "</div>
      </div>
      <div class='progress'></div>
    </div>"

  return medianowHTML

# Update the rendered output.
update: (output, domEl) ->
  # Get our pieces.
  values = output.slice(0,-1).split(" ~ ")

  baseurl = 'http://ws.audioscrobbler.com/2.0/?method=album.getinfo'
  apikey = '2e8c49b69df3c1cf31aaa36b3ba1d166'
  req = baseurl + '&artist=' + encodeURI(values[0]) + '&album=' + encodeURI(values[2]) + '&api_key=' + encodeURI(apikey)
  albumArtwork = false
  # albumArtwork = 'Sidebar.widget/Playbox.widget/as/default.png';

  parseArtworkResponse = (data) ->
    xml = $.parseXML(data)
    $xml = $(xml)
    artwork = $xml.find('image[size="large"]').text()
    return artwork

  getArtwork = (url, cb) ->
    request = new XMLHttpRequest();
    request.open('GET', url, true);
    request.onload = ->
        res = parseArtworkResponse(request.responseText)
        cb(res)

    request.onerror = ->
      console.log('request.onerror');

    request.send();

  getArtwork( req, (artwork) ->
      $(domEl).find('.art__item.top').attr('src', artwork)
  )

  # Get our main DIV.
  div = $(domEl)

  # Initialize our HTML.
  medianowHTML = ''

  # Progress bar things.
  tDuration = values[4]
  tPosition = values[5]
  tArtwork = values[6]
  tWidth = $(domEl).width();
  tCurrent = (tPosition / tDuration) * tWidth

  # currArt = $(domEl).find('.art').css('background-image').split('/').pop().slice(0,-1)
  currArt = $(domEl).find('.art__item.top').attr('src');

  if values[0] == 'NA'
    $(domEl).animate({ opacity: 0 }, 250)
  else
    $(domEl).animate({ opacity: 1 }, 250)
    $(domEl).find('.song').html(values[1])
    $(domEl).find('.artist').html(values[0])
    $(domEl).find('.album').html(values[2])
    $(domEl).find('.progress').css width: tCurrent
    # if albumArtwork isnt currArt
    #   console.log('album artwork is ' + albumArtwork)
    # $(domEl).find('.art__item.top').attr('src', albumArtwork || 'Sidebar.widget/Playbox.widget/as/default.png')

  # Sort out flex-box positioning.
  $(domEl).parent('div').css('order', '7')
  $(domEl).parent('div').css('flex', '0 1 auto')
