require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double Render" if already_built_response?

    @res.set_header('location', url)
    @res.status = 302 # 302 = HTTP status for URL redirection
    session.store_session(@res)

    @already_built_response = true
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Double Render" if already_built_response?

    @res['Content-Type'] = content_type
    @res.write(content)
    session.store_session(@res)

    @already_built_response = true
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise "Double Render" if already_built_response?

    controller_name = self.class.name.underscore
    path = "views/#{controller_name}/#{template_name.to_s}.html.erb"

    content = ERB.new(File.read(path)).result(binding)
    render_content(content, 'text/html')

    @already_built_response = true
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end

