# DocRaptor Rails howto

First you need to get the gem :

    # install (remember to include it in your code in this case)
    > gem install docraptor
    # or put it in your Gemfile
    > echo "gem 'doc_raptor' >> Gemfile"

You need to get your api key (in your DocRaptor dashboard). Now you can write a controller :

    class ApplicationController < ActionController::Base

      def index
        # rails g model Dog name:string color:string
        @examples = Dog.all
        # remark this and change it
        DocRaptor.api_key "YOUR_API_KEY"
  
        doc_raptor_send
      end

      def doc_raptor_send(options = { })
        default_options = {
          :name => controller_name,
          :document_type => :xls,
          :test => ! Rails.env.production?,
        }
        options = default_options.merge(options)
        options[:document_content] ||= render_to_string
        ext = options[:document_type].to_sym
  
        response = DocRaptor.create(options)
        if response.code == 200
          send_data response, :filename => "#{options[:name]}.#{ext}", :type => ext
        else
          render :inline => response.body, :status => response.code
        end
      end

    end

Because a xls is a table you don't need a layout, you just need a view with a HTML table, let's do it in haml :

    %table{ :name => "Excel Example" }
      %tr{ :style => "font-weight:bold;" }
        %td Name
        %td Color
        %td Time
      - @examples.each do |example|
        %tr
          %td=example.name
          %td=example.color
          %td=example.time

Simple isn't it ?

Now if you call the index action you'll get the XLS in return

You'll need to put a proper route and this code doesn't use the format check to handle the process. But you could :

    def index
      @examples = Dog.all
  
      # Don't forget to register the xls/pdf mime types in config/initializers/mime_types.rb
      respond_to do |format|
        format.html
        format.xls { doc_raptor_send }
        format.pdf { doc_raptor_send }
      end
    end

How to register the mime types ?

    Mime::Type.register "application/vnd.ms-excel", :xls
    Mime::Type.register "application/pdf", :pdf


What about Pdf files ? It's just a little bit trickier since you will have to write a layout and take care of the css to (well you could let it blank but then, you'll have a dull doc). You better check PrinceXML styling doc but here is an example.

First the layout (views/layouts/pdf.html.haml):
    !!!
    %html
      %head
        %title Testapp
        %link{:href => "http://fonts.googleapis.com/css?family=OFL+Sorts+Mill+Goudy+TT", :rel => "stylesheet", :type => "text/css"}
        %link{:href => "http://fonts.googleapis.com/css?family=Molengo", :rel => "stylesheet", :type => "text/css"}
        %style{:type =>"text/css"}
          * { font-family: Molengo; }
          p.color { color: #497083;}
          @page {
          size: A4;
          margin: 40pt 30pt 40pt 30pt;
          padding: 10pt 5pt; }
      %body
        %div.container_16{:id => "main"}
          = yield

One thing to notice here : the @page entry. If you check in the PrinceXML doc you'll see that it's the part where you can define the page size, margins, padding etc of your doc. All other CSS things are also used at render time. Note one more thing : to avoid trouble the CSS is included directly in the html file.

Then the view :

    %p Aliquam erat volutpat. Mauris vel neque sit amet nunc gravida congue sed sit amet purus. Quisque lacus quam, egestas ac tincidunt a, lacinia vel velit. Aenean facilisis nulla vitae urna tincidunt congue sed ut dui. Morbi malesuada nulla nec purus convallis consequat. Vivamus id mollis quam. Morbi ac commodo nulla. In condimentum orci id nisl volutpat bibendum. Quisque 

    %p.color Aliquam erat volutpat. Mauris vel neque sit amet nunc gravida congue sed sit amet purus. Quisque lacus quam, egestas ac tincidunt a, lacinia vel velit. Aenean facilisis nulla vitae urna tincidunt congue sed ut dui. Morbi malesuada nulla nec purus convallis consequat. Vivamus id mollis quam. Morbi ac commodo nulla. In condimentum orci id nisl volutpat bibendum. Quisque commodo hendrerit lorem quis egestas. Maecenas quis tortor arcu. Vivamus rutrum nunc non neque consectetur quis placerat neque lobortis. Nam vestibulum, arcu sodales feugiat consectetur, nisl orci bibendum elit, eu euismod magna sapien ut nibh. Donec semper quam scelerisque tortor dictum gravida. In hac habitasse platea dictumst. Nam pulvinar, odio sed rhoncus suscipit, sem diam ultrices mauris, eu consequat purus metus eu velit. Proin metus odio, aliquam eget molestie nec, gravida ut sapien. Phasellus quis est sed turpis sollicitudin venenatis sed eu odio. Praesent eget neque eu eros interdum malesuada non vel leo. Sed fringilla porta ligula egestas tincidunt. Nullam risus magna, ornare vitae varius eget, scele

Yes it's simple I know. Let's check the controller code :

    def pdf
      @examples = Dog.all
      DocRaptor.api_key "YOUR_API_KEY"
      doc_raptor_send_pdf
      #render :layout => "pdf"
    end

    def doc_raptor_send_pdf(options = { })
      default_options = {
        :name => controller_name,
        :document_type => :pdf,
        :test => ! Rails.env.production?,
      }
      options = default_options.merge(options)
      options[:document_content] ||= render_to_string( "application/pdf", :layout => "pdf")
      ext = options[:document_type].to_sym
  
      response = DocRaptor.create(options)
      if response.code == 200
        File.open("#{Rails.root}/tmp/test.pdf", "w") { |fi| fi.puts response.body.force_encoding("ASCII-8BIT").encode("UTF-8") }
        #send_data response, :filename => "#{options[:name]}.#{ext}", :type => ext
        render "worked !"
      else
        render :inline => response.body, :status => response.code
      end
    end

DocRaptor expect the content to be passed as a html string, so you can note here that we pass some args to the __render_to_string__ method. The first one is the view to use, the second one is the layout to use.

With this you should get the a nice little pdf file.

One more thing, because it's nice to get an idea about that : include images in your doc. You need to pass them as Data:URI. uh ? Don't worry it's really easy.

Let's change the previews controller :

    def pdf
      image = IO.read("#{Rails.root}/tmp/image.png")
      @image = ActiveSupport::Base64.encode64(image)
      @examples = Dog.all
      DocRaptor.api_key "YOU_API_KEY"
      doc_raptor_send_pdf
      #render :layout => "pdf"
    end

Basicly Data:URI means "pass it inline, base64 encoded". Luckily Rails comes with some nice methods to do just that. So we start by loading our image as a big chunk of data :

    image = IO.read("#{Rails.root}/tmp/image.png")

Then we encode it in base64 :

    @image = ActiveSupport::Base64.encode64(image)

And let's see how to use this in a view :
    %p
      %img{:src => "data:image/png;base64,#{@image}", :width => "40%"}

And "voila" !

Keep in mind that this whole process (including html rendering, sending and back) might take some time so a nice background task could be of some use here.