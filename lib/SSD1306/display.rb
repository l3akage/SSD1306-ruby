module SSD1306
  # Constants
  SSD1306_I2C_ADDRESS         = 0x3C	# 011110+SA0+RW - 0x3C or 0x3D
  SSD1306_SETCONTRAST         = 0x81
  SSD1306_DISPLAYALLON_RESUME = 0xA4
  SSD1306_DISPLAYALLON        = 0xA5
  SSD1306_NORMALDISPLAY       = 0xA6
  SSD1306_INVERTDISPLAY       = 0xA7
  SSD1306_DISPLAYOFF          = 0xAE
  SSD1306_DISPLAYON           = 0xAF
  SSD1306_SETDISPLAYOFFSET    = 0xD3
  SSD1306_SETCOMPINS          = 0xDA
  SSD1306_SETVCOMDETECT       = 0xDB
  SSD1306_SETDISPLAYCLOCKDIV  = 0xD5
  SSD1306_SETPRECHARGE        = 0xD9
  SSD1306_SETMULTIPLEX        = 0xA8
  SSD1306_SETLOWCOLUMN        = 0x00
  SSD1306_SETHIGHCOLUMN       = 0x10
  SSD1306_SETSTARTLINE        = 0x40
  SSD1306_MEMORYMODE          = 0x20
  SSD1306_COLUMNADDR          = 0x21
  SSD1306_PAGEADDR            = 0x22
  SSD1306_COMSCANINC          = 0xC0
  SSD1306_COMSCANDEC          = 0xC8
  SSD1306_SEGREMAP            = 0xA0
  SSD1306_CHARGEPUMP          = 0x8D
  SSD1306_EXTERNALVCC         = 0x1
  SSD1306_SWITCHCAPVCC        = 0x2

  # Scrolling constants
  SSD1306_ACTIVATE_SCROLL   = 0x2F
  SSD1306_DEACTIVATE_SCROLL = 0x2E
  SSD1306_SET_VERTICAL_SCROLL_AREA = 0xA3
  SSD1306_RIGHT_HORIZONTAL_SCROLL  = 0x26
  SSD1306_LEFT_HORIZONTAL_SCROLL   = 0x27
  SSD1306_VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL = 0x29
  SSD1306_VERTICAL_AND_LEFT_HORIZONTAL_SCROLL  = 0x2A

  class Display
    attr_accessor :protocol, :path, :address, :width, :height, :buffer, :vccstate, :interface, :cursor

    def initialize(opts = {})
      default_options = {
        protocol: :i2c,
        path:     '/dev/i2c-1',
        address:  0x3C,
        width:    128,
        height:   64,
        reset:    24,
        vccstate: SSD1306_SWITCHCAPVCC
      }
      options = default_options.merge(opts)

      @protocol = options[:protocol]
      @path     = options[:path]
      @address  = options[:address]
      @width    = options[:width]
      @height   = options[:height]
      @vccstate = options[:vccstate]
      @pages    = @height / 8
      @buffer   = [0]*(@width*@pages)
      @cursor   = Cursor.new
      @reset    = options[:reset]
      if @protocol == :i2c
        @interface = I2C.create(@path)
      elsif @protocol == :spi
        raise 'SPI Not Supported Currently'
      else
        raise 'Unrecognized protocol'
      end

      # For 128 x 64 display
      if @height == 64
        self.command SSD1306_DISPLAYOFF
        self.command SSD1306_SETDISPLAYCLOCKDIV
        self.command 0x80
        self.command SSD1306_SETMULTIPLEX
        self.command 0x3F
        self.command SSD1306_SETDISPLAYOFFSET
        self.command 0x0
        self.command(SSD1306_SETSTARTLINE | 0x0)
        self.command SSD1306_CHARGEPUMP
        if @vccstate == SSD1306_EXTERNALVCC
          self.command 0x10
        else
          self.command 0x14
        end
        self.command SSD1306_MEMORYMODE
        self.command 0x00
        self.command(SSD1306_SEGREMAP | 0x1)
        self.command SSD1306_COMSCANDEC
        self.command SSD1306_SETCOMPINS
        self.command 0x12
        self.command SSD1306_SETCONTRAST
        if @vccstate == SSD1306_EXTERNALVCC
          self.command 0x9F
        else
          self.command 0xCf
        end
        self.command SSD1306_SETPRECHARGE
        if @vccstate == SSD1306_EXTERNALVCC
          self.command 0x22
        else
          self.command 0xF1
        end
        self.command SSD1306_SETVCOMDETECT
        self.command 0x40
        self.command SSD1306_DISPLAYALLON_RESUME
        self.command SSD1306_NORMALDISPLAY
      end

      self.command SSD1306_DISPLAYON
      self.clear!
    end

    def reset
      #TODO Reset logic
    end

    def debug_buffer # 1024 entries, not all of them are 0x00
      @buffer = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0xC0, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xF8, 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x80, 0x80, 0x00, 0x00, 0x80, 0xFF, 0xFF, 0x80, 0x80, 0x00, 0x80, 0x80, 0x00, 0x80, 0x80, 0x80, 0x80, 0x00, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x00, 0x00, 0x8C, 0x8E, 0x84, 0x00, 0x00, 0x80, 0xF8, 0xF8, 0xF8, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xE0, 0xE0, 0xC0, 0x80, 0x00, 0xE0, 0xFC, 0xFE, 0xFF, 0xFF, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFF, 0xC7, 0x01, 0x01, 0x01, 0x01, 0x83, 0xFF, 0xFF, 0x00, 0x00, 0x7C, 0xFE, 0xC7, 0x01, 0x01, 0x01, 0x01, 0x83, 0xFF, 0xFF, 0xFF, 0x00, 0x38, 0xFE, 0xC7, 0x83, 0x01, 0x01, 0x01, 0x83, 0xC7, 0xFF, 0xFF, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x01, 0x01, 0x00, 0xFF, 0xFF, 0x07, 0x01, 0x01, 0x01, 0x00, 0x00, 0x7F, 0xFF, 0x80, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x7F, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x0F, 0x3F, 0x7F, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE7, 0xC7, 0xC7, 0x8F, 0x8F, 0x9F, 0xBF, 0xFF, 0xFF, 0xC3, 0xC0, 0xF0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xF8, 0xF8, 0xF0, 0xF0, 0xE0, 0xC0, 0x00, 0x01, 0x03, 0x03, 0x03, 0x03, 0x03, 0x01, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x03, 0x03, 0x03, 0x01, 0x01, 0x03, 0x01, 0x00, 0x00, 0x00, 0x01, 0x03, 0x03, 0x03, 0x03, 0x01, 0x01, 0x03, 0x03, 0x00, 0x00, 0x00, 0x03, 0x03, 0x00, 0x00, 0x00, 0x03, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0x03, 0x03, 0x03, 0x03, 0x01, 0x00, 0x00, 0x00, 0x01, 0x03, 0x01, 0x00, 0x00, 0x00, 0x03, 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xC0, 0xE0, 0xF0, 0xF9, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x3F, 0x1F, 0x0F, 0x87, 0xC7, 0xF7, 0xFF, 0xFF, 0x1F, 0x1F, 0x3D, 0xFC, 0xF8, 0xF8, 0xF8, 0xF8, 0x7C, 0x7D, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0x3F, 0x0F, 0x07, 0x00, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xE0, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0xFE, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F, 0x7F, 0x3F, 0x1F, 0x0F, 0x07, 0x1F, 0x7F, 0xFF, 0xFF, 0xF8, 0xF8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xF8, 0xE0, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFE, 0xFE, 0x00, 0x00, 0x00, 0xFC, 0xFE, 0xFC, 0x0C, 0x06, 0x06, 0x0E, 0xFC, 0xF8, 0x00, 0x00, 0xF0, 0xF8, 0x1C, 0x0E, 0x06, 0x06, 0x06, 0x0C, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFE, 0xFE, 0x00, 0x00, 0x00, 0x00, 0xFC, 0xFE, 0xFC, 0x00, 0x18, 0x3C, 0x7E, 0x66, 0xE6, 0xCE, 0x84, 0x00, 0x00, 0x06, 0xFF, 0xFF, 0x06, 0x06, 0xFC, 0xFE, 0xFC, 0x0C, 0x06, 0x06, 0x06, 0x00, 0x00, 0xFE, 0xFE, 0x00, 0x00, 0xC0, 0xF8, 0xFC, 0x4E, 0x46, 0x46, 0x46, 0x4E, 0x7C, 0x78, 0x40, 0x18, 0x3C, 0x76, 0xE6, 0xCE, 0xCC, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x07, 0x0F, 0x1F, 0x1F, 0x3F, 0x3F, 0x3F, 0x3F, 0x1F, 0x0F, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x00, 0x00, 0x03, 0x07, 0x0E, 0x0C, 0x18, 0x18, 0x0C, 0x06, 0x0F, 0x0F, 0x0F, 0x00, 0x00, 0x01, 0x0F, 0x0E, 0x0C, 0x18, 0x0C, 0x0F, 0x07, 0x01, 0x00, 0x04, 0x0E, 0x0C, 0x18, 0x0C, 0x0F, 0x07, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x00, 0x00, 0x0F, 0x0F, 0x0F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0F, 0x0F, 0x00, 0x00, 0x00, 0x07, 0x07, 0x0C, 0x0C, 0x18, 0x1C, 0x0C, 0x06, 0x06, 0x00, 0x04, 0x0E, 0x0C, 0x18, 0x0C, 0x0F, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    end

    def command(c)
      control = 0x00
      @interface.write @address, control, c
    end

    def data(d)
      control = 0x40
      @interface.write @address, control, d
    end

    def display!
      self.command SSD1306_COLUMNADDR
      self.command 0
      self.command(@width - 1)
      self.command SSD1306_PAGEADDR
      self.command 0
      self.command(@pages - 1)
      # Write buffer data
      # TODO: This works for I2C only
      control = 0x40
      @interface.write @address, control, @buffer.pack('c*')
    end

    def image(image)
      image.image_type = BilevelType
      pix = image.export_pixels(0, 0, @width, @height, 'I')
      index = 0
      for page in 0...@pages
        for x in 0...@width
          bits = 0
          for bit in [0, 1, 2, 3, 4, 5, 6, 7]
            bits = bits << 1
            bits |= pix[(page*8*@width) + x + ((7-bit)*@width)] == 0 ? 0 : 1
          end
          @buffer[index] = bits
          index += 1
        end
      end
    end

    def clear
      @buffer = [0]*(@width*@pages)
      @cursor.reset
    end

    def clear!
      self.clear
      self.display!
    end

    def print(string)
      string.each_byte do |c|
        self.print_char c
      end
      string
    end

    def println(string)
      string.each_byte do |c|
        self.print_char c
      end
      self.print_char 10 # 10 is ASCII for \n
      string
    end

    def font_size
      return @cursor.size
    end

    def font_size=(new_size)
      @cursor.size = new_size
    end

    # TODO: Implement Contrast functionality
    def set_contrast(contrast)
      raise 'Contrast not yet implemented'
    end

    # TODO: Implement Dimming functionality
    # Dim the display
    # dim = true: display is dimmed
    # dim = false: display is normal
    def dim(dim)
      # raise 'Dim not implemented yet'
      if dim
        contrast = 0
      elsif @vccstate == SSD1306_EXTERNALVCC
        contrast = 0x9F
      else
        contrast = 0xCF
      end
      puts contrast
      self.command SSD1306_SETCONTRAST
      self.command contrast
    end


    protected

    # This skips to a newline if the byte is a LF newline,
    # otherwise it prints the character, but only if it is
    # in fact a character (i.e., ASCII greater than 31).
    def print_char(b)
      if b == 10
        @cursor.newline
      elsif b > 31
        for i in 0...5
          if @cursor.size == 1
            @buffer[@cursor.buffer_index + i] = FONT[(b*5) + i]
          else
            byte = FONT[(b*5) + i].to_s(2).rjust(8, '0')
            a = byte.chars.each_slice(8/@cursor.size).map(&:join)
            bytes = []
            a.each do |e|
              bytes << e.chars.map {|c| c*(8/e.length)}.join
            end
            bytes = bytes.map {|b| b.to_i(2)}
            bytes.reverse!
            for page in 0...@cursor.size
              for x_interval in 0...@cursor.size
                @buffer[@cursor.buffer_index(page) + i*@cursor.size + x_interval] = bytes[page]
              end
            end
          end
        end
        @cursor.increment
      end
    end
  end
end
