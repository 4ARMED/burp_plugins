$:.unshift '/Library/Frameworks/JRuby.framework/Versions/Current/lib/ruby/1.9'

require 'java'
require 'json'

java_import 'burp.IBurpExtender'
java_import 'burp.IMessageEditorTabFactory'
java_import 'burp.IMessageEditorTab'
java_import 'burp.IParameter'
java_import 'burp.IRequestInfo'
java_import 'burp.IHttpRequestResponse'

class BurpExtender
	include IBurpExtender, IMessageEditorTabFactory, IMessageEditorTab	

	def registerExtenderCallbacks(callbacks)

		# keep a reference to our callbacks object
		@callbacks = callbacks

		# obtain an extension helpers object
		@helpers = callbacks.getHelpers

		# set our extension name
		callbacks.setExtensionName("JSON Beautifier")

		# register ourselves as a message editor tab factory
    callbacks.registerMessageEditorTabFactory(self)

	end

	def createNewInstance(controller, editable)
		JSONTab.new(self, controller, editable)
	end

	# getters
	def callbacks
		@callbacks
	end

	def helpers
		@helpers
	end

end

class JSONTab
	include IMessageEditorTab	

	def initialize(extender, controller, editable)

		# create our callbacks and helpers instance variables
		@callbacks = extender.callbacks
		@helpers = extender.helpers

		@text_editor = @callbacks.createTextEditor
		@text_editor.setEditable(editable)

		@current_message = "" # where we will store the premodified message later
	end

	def getTabCaption
		"JSON"
	end

	def getUiComponent
		@text_editor.getComponent
	end

	def isEnabled(content, isRequest)
    if isRequest
      headers = @helpers.analyzeRequest(content).getHeaders
    else
      headers = @helpers.analyzeResponse(content).getHeaders
    end
    
    headers.to_a.each do |h|    
      if h.match(/^Content-Type:/i)
        ha = h.split(/:/)
        if ha[1].lstrip!.match(/^application\/json\;?/i)
          return true
        else
          return false
        end
      end
    end
	end

	def isModified
		@text_editor.isTextModified
	end

	def setMessage(content, isRequest)
		if content.nil?
			# clear the display
			@text_editor.setText(nil)
			@text_editor.setEditable(false)
		else
			# set the message in the editor window
      if isRequest
        r = @helpers.analyzeRequest(content)
      else
        r = @helpers.analyzeResponse(content)
      end
            
      raw_json = content[r.getBodyOffset..-1].to_s
      pretty_json = JSON.pretty_generate(JSON.parse(raw_json))

      #@text_editor.setText(@helpers.stringToBytes(headers))
      @text_editor.setText(@helpers.stringToBytes(pretty_json))
			@text_editor.setEditable(true)
		end

		# remember the displayed content
		@current_message = content
		return
	end

	def getMessage
		# did the user modify the data?
		if @text_editor.isTextModified
			# yes, they did
			text = @text_editor.getText
      # TODO: need to do stuff with it
		else
			@current_message
		end
	end
end
