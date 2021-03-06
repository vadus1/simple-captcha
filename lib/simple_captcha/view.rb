module SimpleCaptcha #:nodoc
  module ViewHelper #:nodoc

    # Simple Captcha is a very simplified captcha.
    #
    # It can be used as a *Model* or a *Controller* based Captcha depending on what options
    # we are passing to the method show_simple_captcha.
    #
    # *show_simple_captcha* method will return the image, the label and the text box.
    # This method should be called from the view within your form as...
    #
    # <%= show_simple_captcha %>
    #
    # The available options to pass to this method are
    # * label
    # * object
    #
    # <b>Label:</b>
    #
    # default label is "type the text from the image", it can be modified by passing :label as
    #
    # <%= show_simple_captcha(:label => "new captcha label") %>.
    #
    # *Object*
    #
    # This option is needed to create a model based captcha.
    # If this option is not provided, the captcha will be controller based and
    # should be checked in controller's action just by calling the method simple_captcha_valid?
    #
    # To make a model based captcha give this option as...
    #
    # <%= show_simple_captcha(:object => "user") %>
    # and also call the method apply_simple_captcha in the model
    # this will consider "user" as the object of the model class.
    #
    # *Examples*
    # * controller based
    # <%= show_simple_captcha(:label => "Human Authentication: type the text from image above") %>
    # * model based
    # <%= show_simple_captcha(:object => "person", :label => "Human Authentication: type the text from image above") %>
    #
    # Find more detailed examples with sample images here on my blog http://EXPRESSICA.com
    #
    # All Feedbacks/CommentS/Issues/Queries are welcome.
    def show_simple_captcha(options={})
      key = simple_captcha_key(options[:object])
      options[:field_value] = set_simple_captcha_data(key, options)

      defaults = {
         image:          simple_captcha_image(key, options),
         label:          simple_captcha_label(options),
         field:          simple_captcha_field(options),
         refresh_button: simple_captcha_refresh_button(options)
         }

      partial = options[:partial] || 'simple_captcha/simple_captcha'
      render partial: partial, :locals => { :simple_captcha_options => defaults }
    end

    private

      def simple_captcha_label(options = {})
        html = {id: options[:label_id]}
        text = options[:label] || I18n.t('simple_captcha.label')
        if options[:input_html]
          name = options[:input_html][:id] || 'captcha'
        else
          name = 'captcha'
        end

        label_tag(name, text, html)
      end

      def simple_captcha_image(simple_captcha_key, options = {})
        defaults = {}
        defaults[:time] = options[:time] || Time.now.to_i

        query = defaults.collect{ |key, value| "#{key}=#{value}" }.join('&')
        url = "#{ENV['RAILS_RELATIVE_URL_ROOT']}/simple_captcha?code=#{simple_captcha_key}&#{query}"

        tag('img', :src => url, :alt => 'captcha', :id => 'captcha_image')
      end

      def simple_captcha_image_url(simple_captcha_key, options = {})
        defaults = {}
        defaults[:time] = options[:time] || Time.now.to_i

        query = defaults.collect{ |key, value| "#{key}=#{value}" }.join('&')
        "#{ENV['RAILS_RELATIVE_URL_ROOT']}/simple_captcha?code=#{simple_captcha_key}&#{query}"
      end

      def simple_captcha_field(options={})
        html = {:autocomplete => 'off', :required => 'required'}
        html.merge!(options[:input_html] || {})
        html[:placeholder] = options[:placeholder] || I18n.t('simple_captcha.placeholder')

        if options[:object]
          text_field(options[:object], :captcha, html.merge(:value => '')) +
          hidden_field(options[:object], :captcha_key, {:value => options[:field_value]})
        else
          text_field_tag(:captcha, nil, html) +
          hidden_field_tag(:captcha_key, options[:field_value])
        end
      end

      def simple_captcha_refresh_button(options={})
        html = {remote: true}
        html.merge!(options[:refresh_button_html] || {})
        text = options[:refresh_button_text] || :refresh

        link_to(text, "#{ENV['RAILS_RELATIVE_URL_ROOT']}/simple_captcha", html)
      end

      def set_simple_captcha_data(key, options={})
        code_type = options[:code_type]

        value = generate_simple_captcha_data(code_type)
        data = SimpleCaptcha::SimpleCaptchaData.get_data(key)
        data.value = value
        data.save
        key
      end

      def generate_simple_captcha_data(code)
        value = ''

        case code
          when 'numeric' then
            SimpleCaptcha.length.times{value << (48 + rand(10)).chr}
          else
            SimpleCaptcha.length.times{value << (65 + rand(26)).chr}
        end

        return value
      end

      def simple_captcha_key(key_name = nil, request = request)
        if key_name.nil?
          request.session[:captcha] ||= SimpleCaptcha::Utils.generate_key(request.session[:id].to_s, 'captcha')
        else
          SimpleCaptcha::Utils.generate_key(request.session[:id].to_s, key_name)
        end
      end
  end
end
