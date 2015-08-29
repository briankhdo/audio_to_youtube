class AudioToYoutube
	@outputFile = 'out.mp4'
	@tempFolder = 'temp'
	@tempBg = 'bg.jpg'
	@backgroundBase = 'media/bg-720.png'
	@ffmpegDir = 'setme'
	@imagemagickDir = 'setme'
private
	def self.exitWithError(message)
		puts ('\nError: ' + message)
	end

	################################################################################
	# Generates the background art for the video
	def self.generateBackground(audio, backgroundBase, output, blur, text)

		blur ||= false
		text ||= ""

		# extract the album art
		tempArt = "#{Dir.pwd}/art.png"
		cmd = ["ffmpeg"]
		cmd += ['-y']
		cmd += ["-i #{audio}"]
		cmd += ['-acodec none']
		cmd += [tempArt]
		puts 'Extracting album art...'
		begin
			unless Dir.exist?(@tempFolder) ||
				Dir.mkdir(@tempFolder)
				puts p cmd.join(' ')
			end
		rescue
			exitWithError('Couldn\'t find album art in the audio file. ' +
				'Use the -background option to select an image file.')
		end

		# now, build the background image
		cmd = ["imagick"]
		cmd += [backgroundBase]

		# draw the blurred album art background
		if blur
			cmd += ['-gravity', 'center']
			cmd += ['(']
			cmd += [tempArt]
			cmd += ['-resize', '1500x']
			cmd += ['-modulate', '90']
			cmd += ['-blur', '0x20']
			cmd += [')']
			cmd += ['-composite']
		end

		# set offsets depending on whether text is drawn
		gravity = 'center'
		offset = []
		shadowOffset = []
		unless text.empty?
			gravity = 'west'
			offset = ['-geometry', '+60+0']
			shadowOffset = ['-geometry', '+30+0']
		end

		# set some settings used twice
		mainArtFront = ['(']
		mainArtFront += [tempArt]
		mainArtFront += ['-resize', 'x720']
		
		mainArtBack = [')']
		mainArtBack += ['-gravity', gravity]
		mainArtBack += ['-composite']
		
		# draw shadow of the main album art
		cmd += mainArtFront
		cmd += ['-background', 'black']
		cmd += ['-shadow', '50x15+0+0']
		cmd += shadowOffset
		cmd += mainArtBack
		
		# draw the main album art
		cmd += mainArtFront
		cmd += offset
		cmd += mainArtBack

		# add in the track metadata text
		unless text.empty?
			labelText = text[0]
			for i in 1..text.length
				labelText += '\\n\\n' + text[i]
			end

			# set some settings used twice
			labelFront = ['(']
			labelFront += ['-size', '440x400']
			labelFront += ['-background', 'none']
			labelFront += ['-gravity', 'center']
			labelFront += ['-font', 'Segoe-UI-Semibold']
			
			labelMid = ['caption:' + labelText]
			
			labelBack = ['-geometry', '+25+0']
			labelBack += [')']
			labelBack += ['-gravity', 'east']
			labelBack += ['-composite']
		 
			# draw text shadow
			cmd += labelFront.join(' ')
			cmd += ['-fill', '#00000090']
			cmd += labelMid.join(' ')
			cmd += ['-blur', '0x6']
			cmd += labelBack.join(' ')
			
			# draw text itself
			cmd += labelFront.join(' ')
			cmd += ['-fill', 'white']
			cmd += labelMid.join(' ')
			cmd += labelBack.join(' ')

		end

		# put it all together
		cmd += [output]
		puts 'Generating video background...'
		begin
			puts Open3.capture3(cmd.join(' '))
		rescue
			exitWithError('Something went wrong when generating the background.')
		end
	end

	################################################################################
	# Splits text over multiple lines
	def self.splitText(text, maximumLength)

		maximumLength ||= 20
		words = text.split(' ')
		output = ''
		currentLine = ''
		words.each do |word|
			if currentLine == ''
				currentLine = word
			else
				temp = currentLine + ' ' + word
				# with next word, still under maximum length - add normally
				if len(temp) < maximumLength
					currentLine = temp
				# next word is longer than the maximum length - it gets its own line
				elsif len(word) > maximumLength
					if output != ''
						output += r'\n'
					end
					output += currentLine
					currentLine = ''
					if output != ''
						output += r'\n'
					end
					output += word
				# we've overrun the maximum length - start a new line with the word
				else
					if output != ''
						output += 'r\n'
					end
					output += currentLine
					currentLine = word
				end
			end
		end
		if output != ''
			output += r'\n'
		end
		output += currentLine
		#print(output)
		return output
	end

	################################################################################
	# Retrieves the title and artist from the file
	def self.getMetadata(file)
		cmd = ["ffprobe"]
		cmd += ['-i', file]
		print('Extracting metadata...')
		lines = ""
		begin
			output = p cmd.join(' ')
			lines = output.split('\n')
		rescue
			exitWithError('Couldn\'t extract metadata from the file.')
		end

		title = ""
		artist = ""

		lines.each do |line|
			match = line.scan(/^\s*(.*?)\s*: (.*?)\s*@/)
			if match.length > 0
				pair = match[0]
				
				if len(pair) == 2
					if pair[0] == 'title' and pair[1].length > 0
						if title == "" # or len(title) < len(pair[1]):
							title = pair[1]
							print("Found title: " + title)
						end
					elsif pair[0] == 'artist' and pair[1].length > 0
						if artist == "" # or len(artist) < len(pair[1]):
							artist = pair[1]
							print("Found artist: " + artist)
						end
					end
				end
			end
		end
		return artist, title
	end
	################################################################################
	# Creates the final video suitable for uploading
	def self.encode(audio, background, output)
		cmd = ["ffmpeg"]
		cmd += ['-y']
		cmd += ['-loop', '1']
		cmd += ['-r', '1']
		cmd += ['-i', background]
		cmd += ['-i', audio]
		cmd += ['-c:v', 'libx264']
		cmd += ['-preset', 'veryfast']
		cmd += ['-tune', 'stillimage']
		cmd += ['-crf', '15']
		cmd += ['-pix_fmt', 'yuv420p']
		cmd += ['-strict', 'experimental']
		cmd += ['-c:a', 'aac']
		cmd += ['-b:a', '256k']
		cmd += ['-shortest']
		cmd += ['-threads', '0']
		cmd += [output]
		print('Encoding video...')
		begin
			system(cmd.join(' '))
		rescue
			exitWithError('Something went wrong when encoding the video.')
		end
		print('\nDone. Saved output as "%s".' % @outputFile)
	end

	################################################################################
	# Set library locations
	def self.setLibraryLocations()
		
		# set FFmpeg location
		if @ffmpegDir == 'setme' or @ffmpegDir == ''
			@ffmpegDir = '/usr/local/bin'
		end
		
		# set ImageMagick location
		if @imagemagickDir == 'setme' or @imagemagickDir == ''
			@imagemagickDir = '/usr/local/bin'
		end

		# set full paths	
		ffprobe = Dir.pwd + " " + @ffmpegDir + ' ffprobe'
		ffmpeg = Dir.pwd + " " + @ffmpegDir + ' ffmpeg'
		imagick = Dir.pwd + " " + @imagemagickDir + ' convert'

		# ensure libraries are actually installed
		unless (os.path.exists(ffprobe) and os.path.exists(ffmpeg))
			exitWithError("FFmpeg couldn\'t be found at \"#{@ffmpegDir}\". " +
				'Please check your configuration.')
		end
		unless os.path.exists(imagick)
			exitWithError("ImageMagick couldn\'t be found at \"#{@imagemagickDir}\". " +
				'Please check your configuration.')
		end
	end
public
	################################################################################
	# Program entrypoint.
	def self.generate *args
		audio = nil
		bg = nil
		out = nil
		if args.size < 1 || args.size > 3
			puts 'This method takes either 1 to 3 arguments'	
		else
			audio = args[0]
			if args.size == 2
				bg = args[1]
			elsif args.size == 3
				bg = args[1]
				out = args[2]
			end	
		end 

		bg ||= @tempBg
		out ||= @outputFile
		unless File.exist?(audio)
			exitWithError("Input file \"#{audio}\" doesn\'t exist or can\'t be read.")
		end
			
		# determine arguments
		custom = bg
		doBlur = true
		doText = false

		background = Dir.pwd + " " + @tempFolder + " " + bg

		# grab metadata if necessary
		text = ""
		if doText and custom == ""
			metadata = getMetadata(audio)
			metadata.each do |item|
				if item != ""
					#split = splitText(item)
					text.append(item)
				end
			end
		end

		# generate the background unless a premade one is specified
		if custom == ""
			generateBackground(audio, backgroundBase, background, blur=doBlur, text=text)
		else
			background = custom
		end
		encode(audio, background, out)
	end

end