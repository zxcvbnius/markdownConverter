
Common Libraries
=================

      fs         = require 'fs'
      path       = require 'path'


Common Variables
=================

      input      = process.argv[2]
      output     = process.argv[3]


Markdown Settings
-------------

      opts = xhtmlOut:     true
             , breaks:       true
             , linkify:      true
             , langPrefix:   'language-'
             , typographer:  true
             , quotes: '“”‘’'
             , highlight: () -> ''


      MarkdownIt = require 'markdown-it'
      md         = new MarkdownIt()


Parsing Headers
-------------


      md.renderer.rules.heading_open = (tokens, idx, options) ->
        token   = tokens[idx]
        inline  = tokens[idx + 1]
        id      = inline.content.replace( new RegExp('[* ]', 'g'), '')
        return "<#{token.tag} id=#{id}>"


Parsing Codes
-------------

      md.renderer.rules.fence = (tokens, idx, options) ->
        token = tokens[idx]
        if token.info is 'info'
          return "<div class=\"alert alert-info fade in\">\n#{token.content}\n</div>\n"
        else if token.info is 'success'
          return "<div class=\"alert alert-success fade in\">\n#{token.content}\n</div>\n"

        else if token.info is 'warning'
          return "<div class=\"alert alert-warning fade in\">\n#{token.content}\n</div>\n"
        else  if token.info is 'java'
          return "<pre><code class=\"java\">#{token.content}</code></pre>\n"



Parsing Tables
-------------

      md.renderer.rules.table_open = (tokens, idx, options) ->
        token = tokens[idx]
        return "<div class=\"err-table\">" +
         "<table \"border-top:3px #FFD382 solid;border-bottom:3px #82FFFF solid;\" cellpadding=\"10\" border='0'>"


      md.renderer.rules.table_close = (tokens, idx, options) ->
        return "</table>\n</div>"



Appand <br> behind <hr>
-------------

      md.renderer.rules.hr = (tokens, idx, options) ->
        token = tokens[idx]
        return "<#{token.tag}><br>\n"



Read Markdown
-------------

      data       = fs.readFileSync path.resolve(__dirname, input), 'utf8'


Convert markdown to html
-------------

      result = md.render data


      fs.writeFileSync path.resolve(__dirname, output), result, 'utf8'



      console.log 'DONE!'
