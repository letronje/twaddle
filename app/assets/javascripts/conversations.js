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
      .html (tweetHtml ( root.txt));
    
    var rootContainer = $ ("<div></div>")
      .attr ("class", "root")
      .append(img)
      .append(text)

    $.each (root.c, function (i, child) {
      var img = $ ("<img />")
        .attr ("src", child.uimg)
        .attr ("class", "profile")
      
      var text = $ ("<div></div>")
        .attr ("class", "text")
        .html (tweetHtml ( child.txt));
      
      var c = $ ("<div></div>")
        .attr ("class", "child")
        .append(img)
        .append(text)
      
      rootContainer.append (c)
    })

    $ (document.body).append (rootContainer)

  })
}

function tweetHtml (text) {
  return text
    .replace (/(@[a-zA-Z_]+)/g, "<span class='tweet-text-uname'>$1</span>")
    .replace (/(#[^\s]+)/g, "<span class='tweet-text-hashtag'>$1</span>")
}


