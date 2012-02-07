$ (document).ready (function () {
  renderConversations (data);
})

function p (o) {
  try {
    console.log (o)
  }
  catch (e) {
    
  }
}

function renderConversations(data) {
  // latest convo first
  data = data.sort(function(a, b){
    return b.mid - a.mid;
  });

  $.each (data, function (i, root) {
    var img = $ ("<img />")
      .attr ("src", root.uimg)
      .attr ("class", "profile")

    var text = $ ("<div></div>")
      .attr ("class", "text")
      .html (tweetHtml (root));
    
    var uname = $ ("<div></div>")
      .attr ("class", "tweet-uname")
      .html (root.nick)
    
    var rootContainer = $ ("<div></div>")
      .attr ("class", "root")
      .append(img)
      .append(text)
      .append (uname)

    var children = root.c.sort (function (a, b) {
      return a.id - b.id;
    })
    
    $.each (children, function (i, child) {
      var img = $ ("<img />")
        .attr ("src", child.uimg)
        .attr ("class", "profile")
      
      var className = child.last_hour ? "text today last-hour" : ( child.today ? "text today" : "text");
      
      var text = $ ("<div></div>")
        .attr ("class", className)
        .html (tweetHtml ( child));
      
      var uname = $ ("<div></div>")
      .attr ("class", "tweet-uname")
      .html (child.nick)
      
      var c = $ ("<div></div>")
        .attr ("class", "child")
        .append(img)
        .append(text)
        .append(uname)
      rootContainer.append (c)
    })

    $ (document.body).append (rootContainer)

  })
}

function tweetHtml (tweet) {
  return tweet.txt
    .replace (/(@[a-zA-Z_]+)/g, "<span class='tweet-text-uname'>$1</span>")
    .replace (/(#[^\s]+)/g, "<span class='tweet-text-hashtag'>$1</span>")
    .replace (/(http:\/\/[^\s]+)/g, "<a target='_blank' href='$1'>$1</a>")
}


