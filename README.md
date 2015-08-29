# Audio to youtube
Convert audio with background image to mp4 for uploading to youtube using ffmpeg.

Based on a python script: https://github.com/ianharmon/mp3-to-youtube

## Install
```
gem install audio_to_youtube
```

## Usage
```
require 'audio_to_youtube'
AudioToYoutube.generate audio, background, out
```

## Description
**audio**: audio file name with path

**background**: static background for the output video (will use **bg.jpg** if not specified)

**out**: output filename (will use **out.mp4** as default)

## License
Copyright (C) 2015 Brian Doan
This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
