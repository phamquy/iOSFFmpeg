iOSFFmpeg
=========

FFmpeg player for ios

- Not using SDL
- Render directly to OpenGL layer, use shader to conver YUV<->RGB
- Use Audio Queue Service to handle audio output
- Works on iphone4s
- Audio/Video out of sync on iphone4 and earlier
- Can play all format support by ffmpeg
- Can play local .ts file


Folder structure: 

- FFmpegPlayer: player project 
- ffmpeg-test:  ffmpeg test source code
- ffmpeg-uarch:  prebuilt binary for ios (support both device and simulator)
